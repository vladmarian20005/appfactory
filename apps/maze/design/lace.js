// lace.js — draws a Lacework pattern as SVG markup for the mocks. The same geometry the
// builder implements in ThreadPath.swift: pins at the cell pitch, gimp between cells, one
// thread through pin centres with a loop thrown round every pin it turns on, and a second
// lighter strand along any run that is plaited.

function rng32(seed) {
  return function () {
    seed |= 0; seed = (seed + 0x6D2B79F5) | 0;
    let t = Math.imul(seed ^ (seed >>> 15), 1 | seed);
    t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

// A Hamiltonian path over an N×N grid (optionally masked): a serpentine, then backbite moves.
function hamPath(N, rand, iters, mask) {
  const open = (i) => !mask || mask[i];
  let p = [];
  for (let r = 0; r < N; r++) for (let c = 0; c < N; c++) {
    const i = r * N + (r % 2 ? N - 1 - c : c);
    if (open(i)) p.push(i);
  }
  const nbrs = (i) => {
    const r = Math.floor(i / N), c = i % N, out = [];
    if (r > 0) out.push(i - N); if (r < N - 1) out.push(i + N);
    if (c > 0) out.push(i - 1); if (c < N - 1) out.push(i + 1);
    return out.filter(open);
  };
  for (let k = 0; k < iters; k++) {
    if (rand() < 0.5) p.reverse();
    const end = p[p.length - 1];
    const cand = nbrs(end).filter((x) => x !== p[p.length - 2]);
    if (!cand.length) continue;
    const x = cand[Math.floor(rand() * cand.length)];
    const i = p.indexOf(x);
    if (i < 0) continue;
    const tail = p.splice(i + 1).reverse();
    p.push(...tail);
  }
  return p;
}

// Gimp: every neighbouring pair not consecutive on the path is a candidate; keep `keep` of them.
function gimpFor(N, path, rand, keep, mask) {
  const open = (i) => !mask || mask[i];
  const pos = new Map(path.map((c, i) => [c, i]));
  const out = [];
  for (let r = 0; r < N; r++) for (let c = 0; c < N; c++) {
    const i = r * N + c;
    if (!open(i)) continue;
    for (const j of [i + 1, i + N]) {
      if (j >= N * N) continue;
      if (j === i + 1 && c === N - 1) continue;
      if (!open(j)) continue;
      if (Math.abs(pos.get(i) - pos.get(j)) === 1) continue;
      if (rand() < keep) out.push([i, j]);
    }
  }
  return out;
}

// Straight runs of `min`+ pins that end in a turn (or at the thread's end when `all`).
function plaits(path, taken, min, all) {
  const out = [];
  let runStart = 0;
  const dir = (i) => path[i + 1] - path[i];
  for (let i = 1; i < taken; i++) {
    const turned = i + 1 < taken ? dir(i) !== dir(i - 1) : all;
    if (turned) {
      if (i - runStart + 1 >= min) out.push([runStart, i]);
      runStart = i;
    }
  }
  return out;
}

function drawLace(o) {
  const N = o.N, P = o.pitch, m = P * 0.5, W = N * P;
  const cx = (i) => m + (i % N) * P, cy = (i) => m + Math.floor(i / N) * P;
  const open = (i) => !o.mask || o.mask[i];
  const thread = o.thread || '#31497A', twist = o.twist || '#8FA5D6';
  const ink = o.ink || '#2A2521';
  const steel = o.steel || '#6F7B88', brass = o.brass || '#9C7A2E';
  const taken = o.taken == null ? o.path.length : o.taken;
  const onThread = new Set(o.path.slice(0, taken));
  const r = P * 0.17;
  let s = '';

  // windows: the card is snipped away — drawn by the caller as the pillow showing through
  if (o.mask) {
    for (let i = 0; i < N * N; i++) if (!o.mask[i]) {
      s += `<rect x="${cx(i) - P / 2}" y="${cy(i) - P / 2}" width="${P}" height="${P}" fill="${o.windowFill || '#DDD4C0'}"/>`;
    }
  }

  // gimp
  s += `<g stroke="${ink}" stroke-opacity=".7" stroke-width="2.5" stroke-linecap="round">`;
  for (const [a, b] of o.gimp || []) {
    const ax = cx(a), ay = cy(a), bx = cx(b), by = cy(b);
    const mx = (ax + bx) / 2, my = (ay + by) / 2;
    if (b === a + 1) s += `<path d="M${mx} ${my - P * 0.42}V${my + P * 0.42}"/>`;
    else s += `<path d="M${mx - P * 0.42} ${my}H${mx + P * 0.42}"/>`;
  }
  s += '</g>';

  // the thread
  if (taken > 0) {
    const pts = o.path.slice(0, taken).map((i) => [cx(i), cy(i)]);
    let d = `M${pts[0][0]} ${pts[0][1]}`;
    for (let i = 1; i < pts.length; i++) d += `L${pts[i][0]} ${pts[i][1]}`;
    const c0 = W / 2 + m;
    const lift = o.lift ? ` transform="translate(${c0} ${c0 - 10}) scale(1.04) translate(${-c0} ${-c0})"` : '';
    s += `<g${lift}${o.lift ? ' filter="url(#laceShadow)"' : ''}>`;
    s += `<path d="${d}" fill="none" stroke="${thread}" stroke-width="3.4" stroke-linecap="round" stroke-linejoin="round"/>`;
    // the wrap: a ring of thread thrown round every pin the thread turns on
    for (let i = 1; i < pts.length - 1; i++) {
      const d1 = o.path[i] - o.path[i - 1], d2 = o.path[i + 1] - o.path[i];
      if (d1 !== d2) s += `<circle cx="${pts[i][0]}" cy="${pts[i][1]}" r="${r}" fill="none" stroke="${thread}" stroke-width="2"/>`;
    }
    // plaits: the lighter strand along a straight run
    for (const [a, b] of plaits(o.path, taken, 4, o.plaitAll)) {
      s += `<path d="M${pts[a][0]} ${pts[a][1]}L${pts[b][0]} ${pts[b][1]}" fill="none" stroke="${twist}" stroke-width="1.1" stroke-dasharray="3 3" stroke-linecap="round"/>`;
    }
    if (o.picot) {
      // the gold picot edge: a scalloped hairline round the lifted piece, ten scallops a side
      const x0 = m - P * 0.42, x1 = W - m + P * 0.42, y0 = x0, y1 = x1;
      const n = 22, sw = (x1 - x0) / n, sr = sw / 2;
      let e = `M${x0} ${y0}`;
      for (let k = 0; k < n; k++) e += `A${sr} ${sr} 0 0 1 ${x0 + (k + 1) * sw} ${y0}`;
      for (let k = 0; k < n; k++) e += `A${sr} ${sr} 0 0 1 ${x1} ${y0 + (k + 1) * sw}`;
      for (let k = 0; k < n; k++) e += `A${sr} ${sr} 0 0 1 ${x1 - (k + 1) * sw} ${y1}`;
      for (let k = 0; k < n; k++) e += `A${sr} ${sr} 0 0 1 ${x0} ${y1 - (k + 1) * sw}`;
      s += `<path d="${e}" fill="none" stroke="${o.picot}" stroke-width="1.3" stroke-linejoin="round" opacity=".95"/>`;
    }
    s += '</g>';
  }

  // pins — bare, sunk under the thread, or out (a prick where it stood)
  for (let i = 0; i < N * N; i++) {
    if (!open(i)) continue;
    const x = cx(i), y = cy(i);
    const isStart = i === o.start, isFinish = i === o.finish;
    if (o.pinsOut) {
      s += `<circle cx="${x}" cy="${y}" r="1.3" fill="${ink}" fill-opacity=".28"/>`;
      continue;
    }
    if (o.markers && o.markers.includes(i)) {
      s += `<circle cx="${x + P * 0.26}" cy="${y - P * 0.26}" r="2.4" fill="${o.highlight || '#A8413A'}"/>`;
    }
    if (isStart || isFinish) {
      if (isFinish) s += `<circle cx="${x}" cy="${y}" r="${P * 0.3}" fill="none" stroke="${brass}" stroke-width="1.4" opacity=".85"/>`;
      s += `<circle cx="${x + 0.8}" cy="${y + 1}" r="3.6" fill="${ink}" fill-opacity=".22"/>`;
      s += `<circle cx="${x}" cy="${y}" r="3.6" fill="${brass}"/><circle cx="${x - 1.1}" cy="${y - 1.1}" r="1.1" fill="#F4E4B4"/>`;
      if (isStart && o.breathe) s += `<circle cx="${x}" cy="${y}" r="${P * 0.34}" fill="none" stroke="${brass}" stroke-opacity=".35" stroke-width="1"/>`;
      continue;
    }
    if (onThread.has(i)) {
      s += `<circle cx="${x}" cy="${y}" r="2.2" fill="#4E5966"/>`;
    } else {
      s += `<circle cx="${x + 0.7}" cy="${y + 0.9}" r="2.7" fill="${ink}" fill-opacity=".2"/>`;
      s += `<circle cx="${x}" cy="${y}" r="2.6" fill="${steel}"/><circle cx="${x - 0.8}" cy="${y - 0.8}" r="0.85" fill="#FFFFFF" fill-opacity=".9"/>`;
    }
  }

  // the bobbin, lying at the thread's end
  if (o.bobbin && taken > 0 && taken < o.path.length) {
    const h = o.path[taken - 1], x = cx(h) + P * 0.55, y = cy(h) + P * 0.7;
    s += `<g transform="translate(${x} ${y}) rotate(22)">
      <rect x="-5" y="-16" width="10" height="32" rx="4" fill="#7A4E2E"/>
      <rect x="-5" y="-16" width="4" height="32" rx="3" fill="#FFFFFF" fill-opacity=".14"/>
      <rect x="-5" y="-4" width="10" height="9" rx="1.5" fill="${thread}"/>
      <rect x="-5.2" y="8" width="10.4" height="3" rx="1.2" fill="#A8413A"/>
      <circle cx="0" cy="19" r="2.6" fill="#E8DCC0" stroke="#7A4E2E" stroke-width=".8"/>
    </g>`;
  }
  return { svg: s, size: W + P };
}

function makePattern(N, seed, keep, taken, mask) {
  const rand = rng32(seed);
  const path = hamPath(N, rand, N * N * 6, mask);
  const gimp = gimpFor(N, path, rand, keep, mask);
  return { N, path, gimp, taken: taken == null ? path.length : taken, start: path[0], finish: path[path.length - 1] };
}
