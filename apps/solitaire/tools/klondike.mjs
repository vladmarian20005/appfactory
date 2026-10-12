// Baize · Klondike rules and the one random source, shared by pack.mjs.
// This file is the contract Deal.swift and Table.swift replay: same seed → same cards,
// same move string → same table. Node only, no dependencies.

const MASK = (1n << 64n) - 1n;

/** SplitMix64 over a 64-bit BigInt state, wrapping like Swift's &+ and &*. */
export class SplitMix64 {
  constructor(seed) {
    this.state = BigInt.asUintN(64, BigInt(seed));
  }
  next() {
    this.state = (this.state + 0x9e3779b97f4a7c15n) & MASK;
    let z = this.state;
    z = ((z ^ (z >> 30n)) * 0xbf58476d1ce4e5b9n) & MASK;
    z = ((z ^ (z >> 27n)) * 0x94d049bb133111ebn) & MASK;
    return z ^ (z >> 31n);
  }
  /** A double in [0, 1): the top 53 bits over 2^53. */
  unit() {
    return Number(this.next() >> 11n) / 2 ** 53;
  }
}

// Cards: code = suit * 13 + (rank - 1); suits spade, heart, club, diamond.
export const suitOf = (c) => (c / 13) | 0;
export const rankOf = (c) => (c % 13) + 1;
export const isRed = (c) => {
  const s = (c / 13) | 0;
  return s === 1 || s === 3;
};
const SUITS = 'SHCD';
const RANKS = ['', 'A', '2', '3', '4', '5', '6', '7', '8', '9', '10', 'J', 'Q', 'K'];
export const cardName = (c) => RANKS[rankOf(c)] + SUITS[suitOf(c)];

/** The 52 cards in deal order: Fisher–Yates from the end over 0…51. */
export function cards(seed) {
  const deck = Array.from({ length: 52 }, (_, i) => i);
  const rng = new SplitMix64(seed);
  for (let i = 51; i >= 1; i--) {
    const j = Math.floor(rng.unit() * (i + 1));
    const t = deck[i];
    deck[i] = deck[j];
    deck[j] = t;
  }
  return deck;
}

/** FNV-1a 32-bit over the 52 bytes of cards(seed), as 8 lowercase hex chars. */
export function hash(seed) {
  let h = 0x811c9dc5;
  for (const b of cards(seed)) {
    h ^= b;
    h = Math.imul(h, 0x01000193) >>> 0;
  }
  return h.toString(16).padStart(8, '0');
}

/** The laid table. Column c holds c + 1 cards, the first c face down; stock top is last. */
export function table(seed, draw) {
  const deck = cards(seed);
  const columns = [[], [], [], [], [], [], []];
  let idx = 0;
  for (let r = 0; r < 7; r++) for (let c = r; c < 7; c++) columns[c].push(deck[idx++]);
  return {
    draw,
    columns,
    faceDown: [0, 1, 2, 3, 4, 5, 6],
    stock: deck.slice(28),
    waste: [],
    foundations: [[], [], [], []],
    passes: 0,
  };
}

export function clone(t) {
  return {
    draw: t.draw,
    columns: t.columns.map((c) => c.slice()),
    faceDown: t.faceDown.slice(),
    stock: t.stock.slice(),
    waste: t.waste.slice(),
    foundations: t.foundations.map((f) => f.slice()),
    passes: t.passes,
  };
}

/** Can `card` be laid on column `col`? Alternate colour, one lower; a king onto an empty column. */
export function canPlace(card, col) {
  if (col.length === 0) return rankOf(card) === 13;
  const top = col[col.length - 1];
  return rankOf(top) === rankOf(card) + 1 && isRed(top) !== isRed(card);
}

const canUp = (t, card) => rankOf(card) === t.foundations[suitOf(card)].length + 1;

function settle(t, c) {
  const col = t.columns[c];
  if (col.length > 0 && t.faceDown[c] === col.length) {
    t.faceDown[c] -= 1;
    return col[col.length - 1];
  }
  return null;
}

const colIndex = (s) => {
  if (!/^[0-6]$/.test(s)) return -1;
  return Number(s);
};

/**
 * Applies one move string to `t` in place. Returns { turned, gathered } or null if the move
 * is illegal (in which case `t` is unchanged).
 */
export function apply(t, m) {
  const k = m[0];
  if (m === 't') {
    if (t.stock.length > 0) {
      const n = Math.min(t.draw, t.stock.length);
      for (let i = 0; i < n; i++) t.waste.push(t.stock.pop());
      return { turned: null, gathered: false };
    }
    if (t.waste.length > 0) {
      t.stock = t.waste.reverse();
      t.waste = [];
      t.passes += 1;
      return { turned: null, gathered: true };
    }
    return null;
  }
  if (m === 'w') {
    if (t.waste.length === 0) return null;
    const card = t.waste[t.waste.length - 1];
    if (!canUp(t, card)) return null;
    t.foundations[suitOf(card)].push(t.waste.pop());
    return { turned: null, gathered: false };
  }
  if (k === 'w') {
    const c = colIndex(m.slice(1));
    if (c < 0 || t.waste.length === 0) return null;
    const card = t.waste[t.waste.length - 1];
    if (!canPlace(card, t.columns[c])) return null;
    t.columns[c].push(t.waste.pop());
    return { turned: null, gathered: false };
  }
  if (k === 'u') {
    const c = colIndex(m.slice(1));
    if (c < 0) return null;
    const col = t.columns[c];
    if (col.length === 0) return null;
    const card = col[col.length - 1];
    if (!canUp(t, card)) return null;
    t.foundations[suitOf(card)].push(col.pop());
    return { turned: settle(t, c), gathered: false };
  }
  if (k === 'r') {
    const p = m.slice(1).split('.');
    if (p.length !== 3 || !/^\d+$/.test(p[1])) return null;
    const f = colIndex(p[0]);
    const i = Number(p[1]);
    const to = colIndex(p[2]);
    if (f < 0 || to < 0 || f === to) return null;
    const src = t.columns[f];
    if (i < t.faceDown[f] || i >= src.length) return null;
    if (!canPlace(src[i], t.columns[to])) return null;
    const run = src.splice(i);
    t.columns[to].push(...run);
    return { turned: settle(t, f), gathered: false };
  }
  if (k === 'd') {
    const p = m.slice(1).split('.');
    if (p.length !== 2 || !/^[0-3]$/.test(p[0])) return null;
    const s = Number(p[0]);
    const c = colIndex(p[1]);
    if (c < 0) return null;
    const fnd = t.foundations[s];
    if (fnd.length === 0) return null;
    if (!canPlace(fnd[fnd.length - 1], t.columns[c])) return null;
    t.columns[c].push(fnd.pop());
    return { turned: null, gathered: false };
  }
  return null;
}

export const isOut = (t) => t.foundations.every((f) => f.length === 13);

/**
 * Replays a line from the laid table. Returns { won, ok, at, table, turned: [cards in the
 * order they turned face up], gathers }. `ok` is false at the first illegal move (`at`).
 */
export function replay(seed, draw, line) {
  const t = table(seed, draw);
  const moves = Array.isArray(line) ? line : line.split(' ').filter(Boolean);
  const turned = [];
  let gathers = 0;
  for (let i = 0; i < moves.length; i++) {
    const r = apply(t, moves[i]);
    if (!r) return { won: false, ok: false, at: i, table: t, turned, gathers };
    if (r.turned !== null) turned.push(r.turned);
    if (r.gathered) gathers++;
  }
  return { won: isOut(t), ok: true, at: moves.length, table: t, turned, gathers };
}
