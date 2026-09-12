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
/** "siéntate" and "sientate" are the same evidence; the accent is the conjugation's, not ours. */
const fold = (s) => s.normalize("NFD").replace(/[̀-ͯ]/g, "").toLowerCase();

/**
 * Verbs whose conjugations share no stem with their infinitive. There is no rule to derive
 * "voy" from "ir"; there is only the list, and it is short.
 */
const SUPPLETIVE = {
  ir: ["voy", "vas", "va", "vamos", "vais", "van", "fui", "fue", "iba", "ve"],
  irse: ["voy", "vas", "va", "vamos", "van", "fue"],
  ser: ["soy", "eres", "es", "somos", "son", "era", "fue", "fui"],
  haber: ["he", "has", "ha", "hemos", "han", "hay"],
  oir: ["oigo", "oyes", "oye", "oimos", "oyen", "oi"],
};

function prefixes(s) {
  const out = new Set([s.slice(0, Math.max(3, s.length - 2))]);
  // A noun in -z pluralises in -ces: pez → peces, luz → luces.
  if (s.endsWith("z")) out.add(s.slice(0, -1) + "c");
  // A reflexive infinitive is the verb with "se" stuck on: llamarse → llamar → llamo.
  const verb = /(ar|er|ir)se$/.test(s) ? s.slice(0, -2) : s;
  if (/(ar|er|ir)$/.test(verb) && verb.length > 3) {
    const stem = verb.slice(0, -2);
    out.add(stem);
    // conocer → conozco, traducir → traduzco: the c hardens before the ending.
    if (stem.endsWith("c")) out.add(stem.slice(0, -1) + "zc");
    // o → ue or u, u → ue, e → ie or i, at whichever vowel the verb changes: poder → puedo,
    // morir → murió, jugar → juega, querer → quiere, seguir → sigue.
    for (let i = 0; i < stem.length; i++) {
      const swaps = { o: ["ue", "u"], u: ["ue"], e: ["ie", "i"] }[stem[i]] ?? [];
      for (const swap of swaps) out.add(stem.slice(0, i) + swap + stem.slice(i + 1));
    }
  }
  // A two-letter verb stem — usar → us → uso — is short but it is the whole word minus its
  // ending, so it is still evidence the example teaches the word.
  return [...out].filter((p) => p.length >= 2);
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
  // A headword is stored the way it is read — "el / la", "la ventana", "querer a" — so drop
  // the article, and for a phrase keep the word it is really teaching as well as the whole.
  const stems = w.word
    .split(" / ")
    .flatMap((s) => {
      const bare = s.replace(/^(el|la|los|las|un|una)\s+/i, "").trim();
      // For a phrase, any of its content words standing in the example is evidence enough —
      // "darse cuenta" is taught by "no me di cuenta".
      return bare.includes(" ")
        ? [bare, ...bare.split(" ").filter((t) => t.length >= 3)]
        : [bare];
    })
    .filter(Boolean);
  const haystack = ` ${fold(w.example).replace(/[.,¿?¡!;:"]/g, " ")} `;
  const tokens = haystack.trim().split(/\s+/);
  const teaches = stems.some((stem) => {
    const s = fold(stem);
    if (haystack.includes(` ${s} `)) return true;
    if ((SUPPLETIVE[s] ?? []).some((form) => tokens.some((t) => t.startsWith(form)))) return true;
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
