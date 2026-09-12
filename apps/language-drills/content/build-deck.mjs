#!/usr/bin/env node
/**
 * Merge the frequency bands into the deck the app bundles, and refuse to write one that is
 * wrong. The owner's spot-check reads the bands; the app reads the output.
 *
 *   node apps/language-drills/content/build-deck.mjs
 *
 * A wrong translation is the risk SPEC.md names first, so everything mechanical is checked
 * here: ranks are 1…N with no gaps and no repeats, no word appears twice, every theme is one
 * of the twelve, every example actually contains the word it teaches, and nothing is empty.
 */
import fs from "node:fs";
import path from "node:path";

const here = path.dirname(new URL(import.meta.url).pathname);
const out = path.join(here, "..", "ios", "App", "deck.json");

const THEMES = [
  "Everyday",
  "People & family",
  "Food & drink",
  "The house",
  "City & travel",
  "Work & school",
  "Body & health",
  "Time & number",
  "Nature & weather",
  "Going & coming",
  "Feeling & mind",
  "Describing",
];

/**
 * Prefixes an inflected form of `s` may start with. A noun keeps almost all of itself; a verb
 * loses its ending and may change its stem vowel the three ways Spanish changes it — poder →
 * puedo, querer → quiero, seguir → sigue — which is exactly where a naive prefix check fails.
 */
function prefixes(s) {
  const out = new Set([s.slice(0, Math.max(3, s.length - 2))]);
  if (/(ar|er|ir)$/.test(s) && s.length > 3) {
    const stem = s.slice(0, -2);
    out.add(stem);
    const i = Math.max(stem.lastIndexOf("o"), stem.lastIndexOf("e"));
    if (i >= 0) {
      for (const swap of stem[i] === "o" ? ["ue"] : ["ie", "i"]) {
        out.add(stem.slice(0, i) + swap + stem.slice(i + 1));
      }
    }
  }
  return [...out].filter((p) => p.length >= 3);
}

const bands = fs.readdirSync(here).filter((f) => /^band-\d+\.json$/.test(f)).sort();
if (!bands.length) {
  console.error("build-deck: no band-*.json");
  process.exit(2);
}

const words = bands.flatMap((f) => JSON.parse(fs.readFileSync(path.join(here, f), "utf8")));
const problems = [];

const seenRank = new Map();
const seenWord = new Map();
for (const w of words) {
  const at = `rank ${w.rank} "${w.word}"`;
  for (const key of ["word", "translation", "example", "exampleTranslation"]) {
    if (typeof w[key] !== "string" || !w[key].trim()) problems.push(`${at}: ${key} is empty`);
  }
  if (!Number.isInteger(w.theme) || w.theme < 0 || w.theme >= THEMES.length) {
    problems.push(`${at}: theme ${w.theme} is not one of the twelve`);
  }
  if (seenRank.has(w.rank)) problems.push(`${at}: rank repeats "${seenRank.get(w.rank)}"`);
  seenRank.set(w.rank, w.word);
  const key = w.word.toLowerCase();
  if (seenWord.has(key)) problems.push(`${at}: the word repeats rank ${seenWord.get(key)}`);
  seenWord.set(key, w.rank);

  // The example has to teach the word it is under. A headword is stored the way it is read —
  // "el / la", "la ventana", "ser" — so compare on the stems rather than the whole entry, and
  // accept any inflected form that starts the same way, since "puedo" teaches "poder" and
  // "abre" teaches "abrir".
  const stems = w.word
    .split(" / ")
    .map((s) => s.replace(/^(el|la|los|las|un|una)\s+/i, "").trim())
    .filter(Boolean);
  const haystack = ` ${w.example.toLowerCase().replace(/[.,¿?¡!;:"]/g, " ")} `;
  const tokens = haystack.trim().split(/\s+/);
  const teaches = stems.some((stem) => {
    const s = stem.toLowerCase();
    if (haystack.includes(` ${s} `)) return true;
    return prefixes(s).some((p) => tokens.some((t) => t.startsWith(p)));
  });
  if (!teaches) problems.push(`${at}: the example does not contain the word`);
}

for (let r = 1; r <= words.length; r++) {
  if (!seenRank.has(r)) problems.push(`rank ${r} is missing`);
}

if (problems.length) {
  console.error(`build-deck: ${problems.length} problem(s)`);
  for (const p of problems.slice(0, 40)) console.error("  " + p);
  process.exit(1);
}

words.sort((a, b) => a.rank - b.rank);

const perTheme = THEMES.map((_, i) => words.filter((w) => w.theme === i).length);
fs.writeFileSync(out, JSON.stringify({ themes: THEMES, words }, null, 0) + "\n");

console.log(`build-deck: ${words.length} words → ${path.relative(process.cwd(), out)}`);
THEMES.forEach((t, i) => console.log(`  ${String(perTheme[i]).padStart(4)}  ${t}`));
if (words.length !== 1000) {
  console.log(`\nthe deck is ${words.length} words; the app is called Thousand, so it wants 1000.`);
}
