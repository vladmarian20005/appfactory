#!/usr/bin/env node
/**
 * WCAG contrast between pairs of colors, so a palette is checked rather than eyeballed.
 *
 *   node tools/design/contrast.mjs <fg> <bg> [<fg> <bg> ...]      e.g. F4F1FF 0E1230 B3AED8 0E1230
 *
 * Body text needs 4.5:1 (AA); large text — 24pt, or 19pt bold — and glyphs need 3:1. Check
 * ink, inkSoft and onAccent against what they sit on, in light and in dark. Exits 1 if any
 * pair is under 3:1, which nothing readable ever is.
 */
const pairs = process.argv.slice(2).map((h) => h.replace(/^#/, ""));
if (pairs.length < 2 || pairs.length % 2) {
  console.error("usage: contrast.mjs <fg hex> <bg hex> [...]");
  process.exit(1);
}
const lum = (hex) => {
  const [r, g, b] = [0, 2, 4].map((i) => parseInt(hex.slice(i, i + 2), 16) / 255)
    .map((c) => (c <= 0.03928 ? c / 12.92 : ((c + 0.055) / 1.055) ** 2.4));
  return 0.2126 * r + 0.7152 * g + 0.0722 * b;
};
let bad = 0;
for (let i = 0; i < pairs.length; i += 2) {
  const [a, b] = [lum(pairs[i]), lum(pairs[i + 1])];
  const ratio = (Math.max(a, b) + 0.05) / (Math.min(a, b) + 0.05);
  const verdict = ratio >= 7 ? "AAA" : ratio >= 4.5 ? "AA" : ratio >= 3 ? "large text only" : "FAIL";
  if (ratio < 3) bad++;
  console.log(`#${pairs[i]} on #${pairs[i + 1]}  ${ratio.toFixed(2)}:1  ${verdict}`);
}
process.exit(bad ? 1 : 0);
