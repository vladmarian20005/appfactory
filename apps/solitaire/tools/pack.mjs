#!/usr/bin/env node
// Baize · the pack tool. Deals from seeds, proves each deal comes out by search at the draw it
// will be served at, shortens the line, classifies its shape, grades it within its draw, assigns
// the dailies and writes apps/solitaire/ios/App/deals.json. Node only, no dependencies.
//
//   node pack.mjs                 full pack: 450 dailies, 600 draw-one + 1,800 draw-three pool
//   node pack.mjs --limit         quick pass: 20 dailies, 25 + 75 pool
//   node pack.mjs --test          self-test: the RNG, a deal, a proof replayed from scratch
//   flags: --days N --pool1 N --pool3 N --budget N --workers N --out PATH
//
// Every line written is replayed from the laid table with klondike.mjs to all 52 up first.

import { Worker, isMainThread, parentPort, workerData } from 'node:worker_threads';
import { fileURLToPath } from 'node:url';
import { dirname, join, resolve } from 'node:path';
import { writeFileSync, renameSync } from 'node:fs';
import os from 'node:os';
import { SplitMix64, cards, hash, table, replay, apply, isOut, rankOf, suitOf } from './klondike.mjs';

const HERE = dirname(fileURLToPath(import.meta.url));
const MASK = (1n << 64n) - 1n;
const GOLDEN = 0x9e3779b97f4a7c15n;
const POOL_STREAM = 0xba12e5eed0000001n;
const EPOCH = '2026-10-19';
const ENGINE = 1;
const DAILY_WEEK = [4, 18, 32, 46, 74, 102, 150]; // Mon…Sun rungs
const SHAPES = ['buried', 'stock', 'kings', 'passes', 'even'];

const hex16 = (s) => s.toString(16).padStart(16, '0');
const idOf = (s) => (s >> 32n).toString(16).toUpperCase().padStart(8, '0');

export function dailyDials(day) {
  const rung = DAILY_WEEK[day % 7];
  return { rung, grade: Math.min(9, 1 + Math.floor((rung - 1) / 14)), draw: rung >= 40 ? 3 : 1 };
}

// ---------------------------------------------------------------------------------------------
// The search. Its own compact table (stock and waste as one sequence with a cursor), so it can
// be fast; whatever it finds is checked against klondike.mjs before it is trusted.

const RANK = new Int8Array(52);
const SUIT = new Int8Array(52);
const RED = new Uint8Array(52);
for (let c = 0; c < 52; c++) {
  RANK[c] = rankOf(c);
  SUIT[c] = suitOf(c);
  RED[c] = SUIT[c] === 1 || SUIT[c] === 3 ? 1 : 0;
}

const colKey = (col, fd) => String.fromCharCode(65 + fd, ...col.map((c) => c + 48));
const seqKey = (seq) => String.fromCharCode(...seq.map((c) => c + 48));
const keyOf = (s) =>
  s.ck.slice().sort().join('|') + '/' + s.sk + String.fromCharCode(48 + s.cur);

function rootState(seed, draw) {
  const t = table(seed, draw);
  // seq: waste bottom→top, then stock top→bottom; cursor = waste length.
  const seq = t.waste.concat(t.stock.slice().reverse());
  return {
    cols: t.columns,
    ck: t.columns.map((c, i) => colKey(c, t.faceDown[i])),
    fd: t.faceDown.slice(),
    seq,
    sk: seqKey(seq),
    cur: t.waste.length,
    f: [0, 0, 0, 0],
    passes: 0,
    up: 0,
    tu: 0,
  };
}

const child = (s) => ({
  cols: s.cols.slice(),
  ck: s.ck.slice(),
  fd: s.fd.slice(),
  seq: s.seq,
  sk: s.sk,
  cur: s.cur,
  f: s.f.slice(),
  passes: s.passes,
  up: s.up,
  tu: s.tu,
});

const minOpp = (f, card) => (RED[card] ? Math.min(f[0], f[2]) : Math.min(f[1], f[3]));
const canUp = (f, card) => RANK[card] === f[SUIT[card]] + 1;
const isSafe = (f, card) => RANK[card] <= minOpp(f, card) + 2;
const fits = (card, col) => {
  if (col.length === 0) return RANK[card] === 13;
  const top = col[col.length - 1];
  return RANK[top] === RANK[card] + 1 && RED[top] !== RED[card];
};

// Set a column after cards left it, turning the new top face up if needed.
function setFrom(ns, c, col) {
  ns.cols[c] = col;
  if (col.length > 0 && ns.fd[c] === col.length) {
    ns.fd[c] -= 1;
    ns.tu += 1;
  }
  ns.ck[c] = colKey(col, ns.fd[c]);
}
function setTo(ns, c, col) {
  ns.cols[c] = col;
  ns.ck[c] = colKey(col, ns.fd[c]);
}

function upFromCol(s, c) {
  const ns = child(s);
  const col = s.cols[c];
  const card = col[col.length - 1];
  ns.f[SUIT[card]]++;
  ns.up++;
  setFrom(ns, c, col.slice(0, -1));
  return ns;
}

// Take the sequence card at `pos` (after `gathered` recycles); `to` = -1 foundation, else column.
function fromSeq(s, pos, gathered, to) {
  const ns = child(s);
  const card = s.seq[pos];
  const seq = s.seq.slice(0, pos).concat(s.seq.slice(pos + 1));
  ns.seq = seq;
  ns.sk = seqKey(seq);
  ns.cur = pos;
  ns.passes += gathered;
  if (to < 0) {
    ns.f[SUIT[card]]++;
    ns.up++;
  } else {
    setTo(ns, to, s.cols[to].concat([card]));
  }
  return ns;
}

// The waste tops reachable by turning: [pos, turns, gathered], each pos once, fewest turns first.
function reachable(s, draw) {
  const out = [];
  const n = s.seq.length;
  if (n === 0) return out;
  const seen = new Uint8Array(n);
  if (s.cur > 0) {
    seen[s.cur - 1] = 1;
    out.push([s.cur - 1, 0, 0]);
  }
  let c = s.cur;
  let k = 0;
  let g = 0;
  for (;;) {
    if (c < n) {
      c = Math.min(n, c + draw);
      k++;
      if (!seen[c - 1]) {
        seen[c - 1] = 1;
        out.push([c - 1, k, g]);
      }
    } else {
      if (g) break;
      c = 0;
      k++;
      g = 1;
    }
  }
  return out;
}

const turns = (k) => 't '.repeat(k);

function expand(s, draw, out) {
  const { cols, fd, f, seq } = s;
  // Safe cards go up at once, as the only move.
  for (let c = 0; c < 7; c++) {
    const col = cols[c];
    if (col.length === 0) continue;
    const card = col[col.length - 1];
    if (canUp(f, card) && isSafe(f, card)) {
      out.push([upFromCol(s, c), 'u' + c]);
      return;
    }
  }
  if (s.cur > 0) {
    const card = seq[s.cur - 1];
    if (canUp(f, card) && isSafe(f, card)) {
      out.push([fromSeq(s, s.cur - 1, 0, -1), 'w']);
      return;
    }
  }
  let firstEmpty = -1;
  for (let c = 0; c < 7; c++) if (cols[c].length === 0) { firstEmpty = c; break; }

  // Column tops up.
  for (let c = 0; c < 7; c++) {
    const col = cols[c];
    if (col.length && canUp(f, col[col.length - 1])) out.push([upFromCol(s, c), 'u' + c]);
  }
  // Runs between columns.
  for (let F = 0; F < 7; F++) {
    const src = cols[F];
    for (let I = fd[F]; I < src.length; I++) {
      const card = src[I];
      if (I > fd[F]) {
        // A part of a run moves only to free the card under it for its foundation.
        if (!canUp(f, src[I - 1])) continue;
      }
      for (let T = 0; T < 7; T++) {
        if (T === F) continue;
        const dst = cols[T];
        if (dst.length === 0) {
          if (T !== firstEmpty || RANK[card] !== 13 || I === 0) continue;
        } else if (!fits(card, dst)) continue;
        const ns = child(s);
        setTo(ns, T, dst.concat(src.slice(I)));
        setFrom(ns, F, src.slice(0, I));
        out.push([ns, 'r' + F + '.' + I + '.' + T]);
      }
    }
  }
  // Stock and waste: turn to a card, then play it.
  for (const [pos, k, g] of reachable(s, draw)) {
    const card = seq[pos];
    const pre = turns(k);
    if (canUp(f, card)) out.push([fromSeq(s, pos, g, -1), pre + 'w']);
    for (let T = 0; T < 7; T++) {
      const dst = cols[T];
      if (dst.length === 0 ? T === firstEmpty && RANK[card] === 13 : fits(card, dst)) {
        out.push([fromSeq(s, pos, g, T), pre + 'w' + T]);
      }
    }
  }
  // Foundation tops back down, when they might be needed.
  for (let su = 0; su < 4; su++) {
    if (f[su] === 0) continue;
    const card = su * 13 + f[su] - 1;
    if (isSafe(f, card)) continue;
    for (let T = 0; T < 7; T++) {
      const dst = cols[T];
      if (dst.length === 0 ? T === firstEmpty && RANK[card] === 13 : fits(card, dst)) {
        const ns = child(s);
        ns.f[su]--;
        ns.up--;
        setTo(ns, T, dst.concat([card]));
        out.push([ns, 'd' + su + '.' + T]);
      }
    }
  }
}

const OFFSET = 1200;
/**
 * Best-first search, priority cards up × 8 + turned up × 2 − passes × `pw`. Returns
 * { line, effort } or null if not proved within `budget` states.
 */
export function solve(seed, draw, budget, pw = 4) {
  const root = rootState(seed, draw);
  const seen = new Set([keyOf(root)]);
  const buckets = [];
  let top = 0;
  const push = (node) => {
    const s = node.s;
    const p = Math.max(0, s.up * 8 + s.tu * 2 - s.passes * pw + OFFSET);
    (buckets[p] || (buckets[p] = [])).push(node);
    if (p > top) top = p;
  };
  push({ s: root, p: null, m: null });
  const out = [];
  const lineOf = (node) => {
    const parts = [];
    for (let n = node; n.p; n = n.p) parts.push(n.m);
    return parts.reverse().join(' ');
  };
  for (;;) {
    while (top >= 0 && !(buckets[top] && buckets[top].length)) top--;
    if (top < 0) return null;
    const node = buckets[top].pop();
    const s = node.s;
    node.s = null;
    out.length = 0;
    expand(s, draw, out);
    for (const [cs, m] of out) {
      const k = keyOf(cs);
      if (seen.has(k)) continue;
      seen.add(k);
      const cn = { s: cs, p: node, m };
      if (cs.up === 52) return { line: lineOf(cn), effort: seen.size };
      if (seen.size >= budget) return null;
      push(cn);
    }
  }
}

/**
 * Re-time the turns: keep every play in order, but before each play from the waste turn only as
 * often as it takes to bring that card to the top. Returns the new line, or null if it fails
 * (draw three can make a card unreachable under another alignment).
 */
export function retime(seed, draw, line) {
  const moves = line.split(' ');
  const t0 = table(seed, draw);
  const plays = [];
  for (const m of moves) {
    if (m !== 't' && m[0] === 'w') plays.push([m, t0.waste[t0.waste.length - 1]]);
    else if (m !== 't') plays.push([m, -1]);
    if (!apply(t0, m)) return null;
  }
  const t = table(seed, draw);
  const out = [];
  for (const [m, card] of plays) {
    if (card >= 0) {
      const limit = 2 * (t.stock.length + t.waste.length) + 4;
      let k = 0;
      while (!(t.waste.length && t.waste[t.waste.length - 1] === card)) {
        if (++k > limit || !apply(t, 't')) return null;
        out.push('t');
      }
    }
    if (!apply(t, m)) return null;
    out.push(m);
  }
  return isOut(t) ? out.join(' ') : null;
}

/** Greedy pruning: drop any move whose removal still replays to a win, until none does. */
export function shorten(seed, draw, line, maxPasses = 6) {
  let moves = line.split(' ');
  for (let pass = 0; pass < maxPasses; pass++) {
    let changed = false;
    for (let i = moves.length - 1; i >= 0; i--) {
      const cand = moves.slice(0, i).concat(moves.slice(i + 1));
      if (replay(seed, draw, cand).won) {
        moves = cand;
        changed = true;
      }
    }
    if (!changed) break;
  }
  return moves.join(' ');
}

/** The deal's own measures: deepest face-down ace's cover, aces in the stock, kings up. */
function layoutMeasures(seed, draw) {
  const t = table(seed, draw);
  let cover = 0;
  let kingsUp = 0;
  t.columns.forEach((col, c) => {
    col.forEach((card, i) => {
      if (rankOf(card) === 1 && i < t.faceDown[c]) cover = Math.max(cover, col.length - 1 - i);
      if (rankOf(card) === 13 && (i === col.length - 1 || i === 1)) kingsUp++;
    });
  });
  const stockAces = t.stock.filter((c) => rankOf(c) === 1).length;
  return { cover, kingsUp, stockAces, bottom6: t.columns[6][0] };
}

/** Prove, shorten, verify, measure. Returns a record or null. */
// Extra searches that only look for a shorter line once the deal is proved: a heavier pass
// penalty keeps the dealer from going round the stock when it need not. Effort (the grade) is
// always the first, standard search's.
let LINE_PWS = [16, 48];

function polish(seed, draw, raw) {
  if (!replay(seed, draw, raw).won) throw new Error(`search line does not replay for ${hex16(seed)} draw ${draw}`);
  let line = raw;
  for (let round = 0; round < 3; round++) {
    const before = line;
    const rt = retime(seed, draw, line);
    if (rt && rt.split(' ').length <= line.split(' ').length) line = rt;
    line = shorten(seed, draw, line);
    if (line === before) break;
  }
  return line;
}

export function prove(seed, draw, budget) {
  const r = solve(seed, draw, budget);
  if (!r) return null;
  let line = polish(seed, draw, r.line);
  for (const pw of LINE_PWS) {
    const alt = solve(seed, draw, Math.min(budget, 4 * r.effort + 20000), pw);
    if (!alt) continue;
    const l2 = polish(seed, draw, alt.line);
    if (l2.split(' ').length < line.split(' ').length) line = l2;
  }
  const v = replay(seed, draw, line);
  if (!v.won) throw new Error(`shortened line does not replay for ${hex16(seed)}`);
  const m = layoutMeasures(seed, draw);
  const passes = v.gathers;
  const shape =
    m.cover >= 4 ? 'buried' : m.stockAces >= 2 ? 'stock' : m.kingsUp >= 2 ? 'kings' : passes >= 3 ? 'passes' : 'even';
  return {
    id: idOf(seed),
    seed: hex16(seed),
    draw,
    shape,
    line,
    buried: v.turned.length ? v.turned[v.turned.length - 1] : m.bottom6,
    hash: hash(seed),
    effort: r.effort,
    cover: m.cover,
    passes,
    length: line.split(' ').length,
  };
}

// ---------------------------------------------------------------------------------------------
// Grades: ranks over a draw's proved pool, a weighted composite, nine equal parts.

const lowerBound = (a, x) => {
  let lo = 0, hi = a.length;
  while (lo < hi) { const mid = (lo + hi) >> 1; if (a[mid] < x) lo = mid + 1; else hi = mid; }
  return lo;
};
const upperBound = (a, x) => {
  let lo = 0, hi = a.length;
  while (lo < hi) { const mid = (lo + hi) >> 1; if (a[mid] <= x) lo = mid + 1; else hi = mid; }
  return lo;
};
const rankIn = (a, x) => {
  const lo = lowerBound(a, x);
  return (lo + 0.5 * (upperBound(a, x) - lo)) / a.length;
};
const num = (a, b) => a - b;

function composite(stats, d) {
  return (
    0.45 * rankIn(stats.effort, d.effort) +
    0.25 * rankIn(stats.cover, d.cover) +
    0.15 * rankIn(stats.passes, d.passes) +
    0.15 * rankIn(stats.length, d.length)
  );
}

export function poolStats(deals) {
  const stats = {
    effort: deals.map((d) => d.effort).sort(num),
    cover: deals.map((d) => d.cover).sort(num),
    passes: deals.map((d) => d.passes).sort(num),
    length: deals.map((d) => d.length).sort(num),
  };
  const comps = deals.map((d) => composite(stats, d)).sort(num);
  const N = comps.length;
  stats.cuts = [];
  for (let k = 1; k <= 8; k++) stats.cuts.push(comps[Math.min(N - 1, Math.ceil((k * N) / 9))]);
  return stats;
}

export function gradeOf(stats, d) {
  const c = composite(stats, d);
  let g = 1;
  for (const cut of stats.cuts) if (c >= cut) g++;
  return g;
}

// ---------------------------------------------------------------------------------------------
// Workers.

function dayTask({ day, budget, stats, reserved, maxExact, maxAll }) {
  const { draw, grade } = dailyDials(day);
  // The start is mixed once: SplitMix64 steps by GOLDEN, so starting day d at d·GOLDEN made day
  // d+7 the same stream as day d seven draws on — same rung, same deal, a collision.
  const rng = new SplitMix64(new SplitMix64((BigInt(day) * GOLDEN + 1n) & MASK).next());
  const tried = [];
  let candidates = 0;
  while (candidates < maxAll) {
    const seed = rng.next();
    candidates++;
    if (reserved.includes(idOf(seed))) continue;
    const p = prove(seed, draw, budget);
    if (!p) continue;
    p.grade = gradeOf(stats, p);
    if (p.grade === grade) return { day, deal: p, candidates, exact: true };
    tried.push(p);
    if (candidates >= maxExact) {
      let best = tried[0];
      for (const t of tried) if (Math.abs(t.grade - grade) < Math.abs(best.grade - grade)) best = t;
      return { day, deal: best, candidates, exact: false };
    }
  }
  return { day, deal: null, candidates, exact: false };
}

if (!isMainThread) {
  LINE_PWS = workerData.pws;
  let reserved = [];
  parentPort.on('message', (msg) => {
    if (msg.type === 'reserve') {
      reserved = msg.ids;
      return;
    }
    if (msg.type === 'pool') {
      const seed = BigInt('0x' + msg.seed);
      const p = prove(seed, msg.draw, msg.budget);
      parentPort.postMessage({ type: 'pool', idx: msg.idx, deal: p });
    } else if (msg.type === 'day') {
      parentPort.postMessage({ type: 'day', ...dayTask({ ...msg, reserved }) });
    }
  });
}

// ---------------------------------------------------------------------------------------------
// Main.

function args() {
  const a = process.argv.slice(2);
  const o = { days: 450, pool1: 600, pool3: 1800, budget: 400000, workers: os.cpus().length, out: null, test: false };
  for (let i = 0; i < a.length; i++) {
    const k = a[i];
    if (k === '--limit') Object.assign(o, { days: 20, pool1: 25, pool3: 75 });
    else if (k === '--test') {
      o.test = true;
      if (/^\d+$/.test(a[i + 1] || '')) o.testCount = Number(a[++i]);
    }
    else if (k === '--pw') LINE_PWS = a[++i].split(',').filter(Boolean).map(Number);
    else if (k === '--out') o.out = a[++i];
    else if (['--days', '--pool1', '--pool3', '--budget', '--workers'].includes(k)) o[k.slice(2)] = Number(a[++i]);
    else throw new Error('unknown flag ' + k);
  }
  o.out = resolve(o.out || join(HERE, '..', 'ios', 'App', 'deals.json'));
  return o;
}

function selfTest(count = 16, verbose = count <= 16) {
  const c1 = cards(1n);
  console.log('cards(0x0000000000000001) =', JSON.stringify(c1));
  console.log('hash =', hash(1n));
  const rng = new SplitMix64(1n);
  console.log('SplitMix64(1).next() x3 =', [rng.next(), rng.next(), rng.next()].map(hex16).join(' '));
  let ok = 0;
  for (const draw of [1, 3]) {
    const pr = new SplitMix64(POOL_STREAM);
    let n = 0, len = 0, passes = 0, msAll = 0;
    for (let i = 0; i < count; i++) {
      const seed = pr.next();
      const t0 = Date.now();
      const p = prove(seed, draw, 400000);
      const ms = Date.now() - t0;
      msAll += ms;
      if (!p) { if (verbose) console.log(`draw ${draw} ${hex16(seed)} not proved (${ms} ms)`); continue; }
      const v = replay(seed, draw, p.line);
      if (!v.won) throw new Error('self-test replay failed');
      ok++;
      n++; len += p.length; passes += p.passes;
      if (verbose) console.log(`draw ${draw} ${p.seed} effort ${p.effort} len ${p.length} passes ${p.passes} cover ${p.cover} ${p.shape} buried ${p.buried} (${ms} ms)`);
    }
    console.log(`draw ${draw}: proved ${n}/${count}, mean line ${(len / n).toFixed(1)}, mean passes ${(passes / n).toFixed(2)}, ${(msAll / count).toFixed(0)} ms/deal`);
  }
  console.log(`self-test ok: ${ok} proved and replayed`);
}

function runPool(o, pool) {
  return new Promise((done) => {
    const target = { 1: o.pool1, 3: o.pool3 };
    const stream = new SplitMix64(POOL_STREAM);
    const results = new Map(); // idx → deal|null
    const drawOf = (i) => (i % 4 === 0 ? 1 : 3);
    let nextIdx = 0;
    let inflight = 0;
    let finished = false;
    const seeds = [];
    const provedBefore = (draw, idx) => {
      let n = 0;
      for (const [i, d] of results) if (i < idx && d && d.draw === draw) n++;
      return n;
    };
    const prefixDone = () => {
      // Are the first target[d] proved deals per draw all inside a completed prefix?
      const have = { 1: 0, 3: 0 };
      for (let i = 0; i < nextIdx; i++) {
        if (!results.has(i)) {
          if (seeds[i] === null) continue; // skipped
          return false;
        }
        const d = results.get(i);
        if (d) have[d.draw]++;
        if (have[1] >= target[1] && have[3] >= target[3]) return true;
      }
      return false;
    };
    let reported = 0;
    const t0 = Date.now();
    const feed = (w) => {
      for (;;) {
        if (prefixDone()) return false;
        const idx = nextIdx++;
        const seed = stream.next();
        const draw = drawOf(idx);
        if (provedBefore(draw, idx) >= target[draw]) {
          seeds[idx] = null;
          // Both draws already have enough before this point: nothing more to hand out.
          if (provedBefore(4 - draw, idx) >= target[4 - draw]) return false;
          continue;
        }
        seeds[idx] = seed;
        w.postMessage({ type: 'pool', idx, seed: hex16(seed), draw, budget: o.budget });
        inflight++;
        return true;
      }
    };
    for (const w of pool) {
      w.on('message', (msg) => {
        if (msg.type !== 'pool' || finished) return;
        inflight--;
        results.set(msg.idx, msg.deal);
        if (results.size - reported >= 50) {
          reported = results.size;
          const c = { 1: 0, 3: 0 };
          for (const d of results.values()) if (d) c[d.draw]++;
          const tried = { 1: 0, 3: 0 };
          for (const i of results.keys()) tried[drawOf(i)]++;
          console.log(`pool: ${results.size} tried, proved d1 ${c[1]}/${tried[1]} d3 ${c[3]}/${tried[3]}, ${((Date.now() - t0) / 1000).toFixed(0)} s`);
        }
        if (!feed(w) && inflight === 0) {
          finished = true;
          for (const ww of pool) ww.removeAllListeners('message');
          const out = { 1: [], 3: [] };
          const ids = new Set();
          for (let i = 0; i < nextIdx; i++) {
            const d = results.get(i);
            if (!d || out[d.draw].length >= target[d.draw] || ids.has(d.id)) continue;
            ids.add(d.id);
            out[d.draw].push(d);
          }
          const tried = { 1: 0, 3: 0 };
          const proved = { 1: 0, 3: 0 };
          for (const [i, d] of results) { tried[drawOf(i)]++; if (d) proved[d.draw]++; }
          done({ deals: out, tried, proved });
        }
      });
    }
    for (const w of pool) feed(w);
  });
}

function runDays(o, pool, stats, reservedIds) {
  return new Promise((done) => {
    for (const w of pool) w.postMessage({ type: 'reserve', ids: reservedIds });
    const statsFor = { 1: stats[1], 3: stats[3] };
    let next = 0;
    let inflight = 0;
    const out = {};
    const t0 = Date.now();
    const feed = (w) => {
      if (next >= o.days) return false;
      const day = next++;
      w.postMessage({ type: 'day', day, budget: o.budget, stats: statsFor[dailyDials(day).draw], maxExact: 60, maxAll: 300 });
      inflight++;
      return true;
    };
    for (const w of pool) {
      w.on('message', (msg) => {
        if (msg.type !== 'day') return;
        inflight--;
        out[msg.day] = msg;
        const n = Object.keys(out).length;
        if (n % 10 === 0) console.log(`dailies: ${n}/${o.days}, ${((Date.now() - t0) / 1000).toFixed(0)} s`);
        if (!feed(w) && inflight === 0) {
          for (const ww of pool) ww.removeAllListeners('message');
          done(out);
        }
      });
    }
    for (const w of pool) feed(w);
  });
}

const packDeal = (d) => ({
  id: d.id,
  seed: d.seed,
  draw: d.draw,
  grade: d.grade,
  shape: d.shape,
  line: d.line,
  buried: d.buried,
  hash: d.hash,
});

async function main() {
  const o = args();
  if (o.test) return selfTest(o.testCount);
  const T0 = Date.now();
  console.log(`pack: ${o.days} dailies, pool ${o.pool1} d1 + ${o.pool3} d3, budget ${o.budget}, ${o.workers} workers`);
  const pool = Array.from({ length: o.workers }, () => new Worker(fileURLToPath(import.meta.url), { workerData: { pws: LINE_PWS } }));

  const P = await runPool(o, pool);
  console.log(`pool done in ${((Date.now() - T0) / 1000).toFixed(0)} s: tried d1 ${P.tried[1]} (proved ${P.proved[1]}), d3 ${P.tried[3]} (proved ${P.proved[3]})`);
  const stats = {};
  for (const draw of [1, 3]) {
    const deals = P.deals[draw];
    if (deals.length === 0) throw new Error(`no proved deals at draw ${draw}`);
    stats[draw] = poolStats(deals);
    for (const d of deals) d.grade = gradeOf(stats[draw], d);
  }
  const poolDeals = [...P.deals[1], ...P.deals[3]];
  const ids = new Set(poolDeals.map((d) => d.id));

  const T1 = Date.now();
  const D = await runDays(o, pool, stats, [...ids]);
  for (const w of pool) w.terminate();
  const dailies = {};
  let inexact = [];
  for (let day = 0; day < o.days; day++) {
    let r = D[day];
    if (!r || !r.deal) throw new Error(`no daily for day ${day}`);
    if (ids.has(r.deal.id)) {
      // Days are searched in parallel and cannot see each other: search this one again here,
      // past every id already taken.
      console.log(`daily id collision on day ${day}: ${r.deal.id}, searching again`);
      const stats1 = stats[dailyDials(day).draw];
      r = dayTask({ day, budget: o.budget, stats: stats1, reserved: [...ids], maxExact: 60, maxAll: 300 });
      if (!r.deal || ids.has(r.deal.id)) throw new Error(`daily id collision on day ${day}`);
    }
    ids.add(r.deal.id);
    if (!r.exact) inexact.push(`day ${day} wanted ${dailyDials(day).grade} got ${r.deal.grade}`);
    dailies[String(day)] = packDeal(r.deal);
  }
  console.log(`dailies done in ${((Date.now() - T1) / 1000).toFixed(0)} s`);

  // Final check: every deal replays from its seed to all 52 up, and its hash matches.
  for (const d of [...poolDeals, ...Object.values(dailies)]) {
    const seed = BigInt('0x' + d.seed);
    if (!replay(seed, d.draw, d.line).won) throw new Error('unverified deal ' + d.seed);
    if (hash(seed) !== d.hash) throw new Error('hash mismatch ' + d.seed);
  }

  // Shuffle the pool once with SplitMix64(1), Fisher–Yates from the end.
  const shuffled = poolDeals.map(packDeal);
  const rng = new SplitMix64(1n);
  for (let i = shuffled.length - 1; i >= 1; i--) {
    const j = Math.floor(rng.unit() * (i + 1));
    [shuffled[i], shuffled[j]] = [shuffled[j], shuffled[i]];
  }
  const json = JSON.stringify({ engine: ENGINE, epoch: EPOCH, dailies, pool: shuffled });
  const tmp = o.out + '.tmp';
  writeFileSync(tmp, json);
  renameSync(tmp, o.out);

  // Report.
  console.log(`\nwrote ${o.out}: ${(json.length / 1048576).toFixed(2)} MB`);
  console.log(`dailies: ${Object.keys(dailies).length}; inexact grades: ${inexact.length}`);
  for (const s of inexact) console.log('  ' + s);
  const dg = {};
  for (const d of Object.values(dailies)) dg[`d${d.draw} g${d.grade}`] = (dg[`d${d.draw} g${d.grade}`] || 0) + 1;
  console.log('dailies by draw/grade:', JSON.stringify(dg));
  for (const draw of [1, 3]) {
    const deals = P.deals[draw];
    console.log(`\npool draw ${draw}: ${deals.length}`);
    console.log('grade  ' + SHAPES.map((s) => s.padStart(7)).join('') + '  total');
    const thin = [];
    for (let g = 1; g <= 9; g++) {
      const row = SHAPES.map((s) => deals.filter((d) => d.grade === g && d.shape === s).length);
      row.forEach((n, i) => { if (n > 0 && n < 8) thin.push(`g${g} ${SHAPES[i]} ${n}`); });
      console.log(`  ${g}    ` + row.map((n) => String(n).padStart(7)).join('') + String(row.reduce((a, b) => a + b, 0)).padStart(7));
    }
    console.log('  cells under 8: ' + (thin.length ? thin.join(', ') : 'none'));
  }
  console.log(`\ntotal ${((Date.now() - T0) / 1000 / 60).toFixed(1)} min`);
}

if (isMainThread) {
  main().catch((e) => {
    console.error(e);
    process.exit(1);
  });
}
