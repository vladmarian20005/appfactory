#!/usr/bin/env node
// Writes design/art/*.svg from lace.js, so the art's thread is the same geometry as the mocks
// and the app. Run from the repo root: node apps/maze/design/make-art.mjs
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const here = path.dirname(fileURLToPath(import.meta.url));
const lace = fs.readFileSync(path.join(here, "lace.js"), "utf8");
const { makePattern, drawLace } = new Function(`${lace}; return { makePattern, drawLace };`)();
const art = path.join(here, "art");
fs.mkdirSync(art, { recursive: true });

const weave = `<pattern id="wv" width="2.6" height="2.6" patternUnits="userSpaceOnUse"><path d="M0 0H2.6M0 0V2.6" stroke="#2A2521" stroke-opacity=".06" stroke-width=".7"/></pattern>`;
const cornerPins = (pts) => pts.map(([x, y]) =>
  `<circle cx="${x + 1}" cy="${y + 1.5}" r="4.4" fill="#2A2521" opacity=".3"/><circle cx="${x}" cy="${y}" r="4.4" fill="#9C7A2E"/><circle cx="${x - 1.4}" cy="${y - 1.4}" r="1.4" fill="#F0DDA3"/>`).join("");

// 1. The pillow: the bolster in linen, the pricking card pinned to it, a thread part-wound and
//    the bobbin lying at its end. Onboarding 1, the sampler's empty state.
{
  const pat = makePattern(7, 7, 0.3, 27);
  const l = drawLace({ ...pat, pitch: 30, taken: 27, bobbin: true });
  const svg = `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 372 340">
  <defs>
    <linearGradient id="bol" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#E6DECB"/><stop offset=".6" stop-color="#D9CFB9"/><stop offset="1" stop-color="#C9BEA6"/></linearGradient>
    <linearGradient id="crd" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#FBF6EB"/><stop offset="1" stop-color="#EEE5D2"/></linearGradient>
    ${weave}
  </defs>
  <g transform="skewX(-6)">
    <ellipse cx="205" cy="304" rx="160" ry="12" fill="#2A2521" opacity=".10"/>
    <rect x="40" y="70" width="330" height="230" rx="44" fill="url(#bol)"/>
    <rect x="40" y="70" width="330" height="230" rx="44" fill="url(#wv)"/>
    <path d="M62 84 Q205 62 348 84" fill="none" stroke="#F6F0E3" stroke-width="2" opacity=".85"/>
    <path d="M52 250 Q205 292 358 250" fill="none" stroke="#2A2521" stroke-width="1.5" opacity=".08"/>
  </g>
  <g transform="translate(88 92) rotate(-2.5)">
    <rect x="0" y="0" width="240" height="240" rx="8" fill="#2A2521" opacity=".12" transform="translate(4 8)"/>
    <rect x="0" y="0" width="240" height="240" rx="8" fill="url(#crd)"/>
    <svg x="0" y="0" width="240" height="240" viewBox="0 0 ${l.size} ${l.size}">${l.svg}</svg>
    ${cornerPins([[7, 7], [225, 7], [7, 225], [225, 225]])}
  </g>
</svg>`;
  fs.writeFileSync(path.join(art, "pillow.svg"), svg);
}

// 2. Two bobbins crossed, one wound with indigo and one with rose silk, their spangles catching
//    the light. Onboarding 2, the pillow's "today's is in the sampler" state.
{
  const bobbin = (thread, band, x, y, rot) => `
  <g transform="translate(${x} ${y}) rotate(${rot})">
    <ellipse cx="0" cy="118" rx="26" ry="7" fill="#2A2521" opacity=".14"/>
    <rect x="-13" y="-100" width="26" height="200" rx="11" fill="#7A4E2E"/>
    <rect x="-13" y="-100" width="10" height="200" rx="8" fill="#FFFFFF" fill-opacity=".14"/>
    <rect x="-14" y="-104" width="28" height="18" rx="8" fill="#5E3A20"/>
    <rect x="-13" y="-40" width="26" height="64" rx="4" fill="${thread}"/>
    <path d="M-13 -30 H13 M-13 -18 H13 M-13 -6 H13 M-13 6 H13 M-13 18 H13" stroke="#FFFFFF" stroke-opacity=".18" stroke-width="2"/>
    <rect x="-14" y="34" width="28" height="9" rx="4" fill="${band}"/>
    <circle cx="0" cy="112" r="9" fill="#E8DCC0" stroke="#7A4E2E" stroke-width="2.5"/>
    <g fill="#8FA5D6" stroke="#2A2521" stroke-opacity=".3" stroke-width=".6">
      <circle cx="-9" cy="126" r="4"/><circle cx="0" cy="130" r="4.4"/><circle cx="9" cy="126" r="4"/><circle cx="-4" cy="137" r="3.4"/><circle cx="5" cy="137" r="3.4"/>
    </g>
    <path d="M-9 126 Q0 118 9 126" fill="none" stroke="#6F7B88" stroke-width="1.2"/>
  </g>`;
  const svg = `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 372 340">
  <defs>${weave}</defs>
  <ellipse cx="186" cy="290" rx="150" ry="16" fill="#2A2521" opacity=".07"/>
  <path d="M40 300 Q186 262 332 300" fill="none" stroke="#31497A" stroke-width="3.4" stroke-linecap="round" opacity=".9"/>
  <path d="M40 300 Q186 262 332 300" fill="none" stroke="#8FA5D6" stroke-width="1.1" stroke-dasharray="3 3" opacity=".9"/>
  ${bobbin("#31497A", "#A8413A", 150, 160, -22)}
  ${bobbin("#C4586A", "#31497A", 222, 160, 20)}
</svg>`;
  fs.writeFileSync(path.join(art, "bobbins.svg"), svg);
}

// 3. A finished piece lifted off the pillow: lace with a picot edge, its shadow on the card
//    below and the pricks where its pins were. Onboarding 3, the sampler's masthead.
{
  const pat = makePattern(8, 33, 0);
  const l = drawLace({ ...pat, pitch: 30, pinsOut: true, plaitAll: true, picot: "#A8842E", lift: true });
  const svg = `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 372 340">
  <defs>
    <linearGradient id="crd" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#FBF6EB"/><stop offset="1" stop-color="#EEE5D2"/></linearGradient>
    <filter id="laceShadow" x="-20%" y="-20%" width="140%" height="150%"><feDropShadow dx="0" dy="14" stdDeviation="9" flood-color="#2A2521" flood-opacity=".3"/></filter>
    ${weave}
  </defs>
  <g transform="translate(56 42) rotate(-3)">
    <rect x="0" y="0" width="260" height="260" rx="8" fill="#2A2521" opacity=".12" transform="translate(4 8)"/>
    <rect x="0" y="0" width="260" height="260" rx="8" fill="url(#crd)"/>
    ${cornerPins([[8, 8], [252, 8], [8, 252], [252, 252]])}
    <svg x="10" y="10" width="240" height="240" viewBox="0 0 ${l.size} ${l.size}" overflow="visible">${l.svg}</svg>
  </g>
</svg>`;
  fs.writeFileSync(path.join(art, "lace.svg"), svg);
}

// 4. The pattern book open on the pillow: a stack of pricked cards, the top one a medallion,
//    a ribbon marker and a pin cushion. The paywall hero, the book's locked state.
{
  const mask = [];
  const N = 8;
  for (let r = 0; r < N; r++) for (let c = 0; c < N; c++) {
    const clip = (r + c < 2) || (r + (N - 1 - c) < 2) || ((N - 1 - r) + c < 2) || ((N - 1 - r) + (N - 1 - c) < 2);
    mask.push(!clip);
  }
  const pat = makePattern(N, 91, 0.32, 0, mask);
  const l = drawLace({ ...pat, mask, pitch: 24, taken: 0, windowFill: "#EBE3D1", start: pat.path[0], finish: pat.path[pat.path.length - 1] });
  const card = (x, y, rot, inner) => `
  <g transform="translate(${x} ${y}) rotate(${rot})">
    <rect x="0" y="0" width="216" height="216" rx="8" fill="#2A2521" opacity=".10" transform="translate(3 6)"/>
    <rect x="0" y="0" width="216" height="216" rx="8" fill="url(#crd)"/>
    ${inner}
  </g>`;
  const svg = `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 372 340">
  <defs>
    <linearGradient id="crd" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#FBF6EB"/><stop offset="1" stop-color="#EEE5D2"/></linearGradient>
    ${weave}
  </defs>
  <ellipse cx="186" cy="300" rx="160" ry="14" fill="#2A2521" opacity=".08"/>
  ${card(66, 76, -7, "")}
  ${card(74, 66, -3.5, "")}
  ${card(82, 56, 0, `<svg x="0" y="0" width="216" height="216" viewBox="0 0 ${l.size} ${l.size}">${l.svg}</svg>
    <text x="98" y="206" text-anchor="middle" font-family="-apple-system, system-ui, sans-serif" font-size="7.5" font-weight="600" letter-spacing="2" fill="#655B52">PATTERN 61 · A MEDALLION</text>`)}
  <!-- the ribbon marker, down the card's right edge -->
  <path d="M276 56 V302 L287 291 L298 302 V56 Z" fill="#A8413A"/>
  <path d="M276 56 V302 L287 291" fill="none" stroke="#FFFFFF" stroke-opacity=".18" stroke-width="2"/>
  <!-- the pin cushion -->
  <g transform="translate(318 236)">
    <ellipse cx="0" cy="44" rx="34" ry="8" fill="#2A2521" opacity=".12"/>
    <ellipse cx="0" cy="14" rx="34" ry="30" fill="#31497A"/>
    <ellipse cx="0" cy="4" rx="30" ry="18" fill="#3E5A92"/>
    <path d="M-30 4 Q0 -2 30 4" fill="none" stroke="#8FA5D6" stroke-width="1.2" opacity=".6"/>
    <g stroke="#6F7B88" stroke-width="1.6" stroke-linecap="round">
      <path d="M-14 0 L-20 -28"/><path d="M0 -4 L2 -34"/><path d="M14 0 L22 -26"/>
    </g>
    <g fill="#9C7A2E"><circle cx="-20" cy="-30" r="3.4"/><circle cx="2" cy="-36" r="3.4"/><circle cx="22" cy="-28" r="3.4"/></g>
    <g fill="#F0DDA3"><circle cx="-21" cy="-31" r="1"/><circle cx="1" cy="-37" r="1"/><circle cx="21" cy="-29" r="1"/></g>
  </g>
</svg>`;
  fs.writeFileSync(path.join(art, "book.svg"), svg);
}

console.log("wrote", fs.readdirSync(art).join(", "));
