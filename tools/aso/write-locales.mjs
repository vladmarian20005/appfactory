#!/usr/bin/env node
/**
 * Write App Store metadata files for one or more localizations from a single JSON file.
 *
 *   node tools/aso/write-locales.mjs apps/<slug>/store/metadata <listing.json>
 *
 * listing.json:
 *   { "es-MX": { "name": "...", "subtitle": "...", "keywords": "a,b,c",
 *                "promotional_text": "...", "description": "...", "release_notes": "..." }, ... }
 *
 * One file per field, as `deliver` reads them, with no trailing newline (the limits are
 * counted in characters and a stray newline is a character). privacy_url and support_url
 * are copied from en-US: the pages are the same in every language. Keywords are normalised
 * (trimmed, lower-cased, de-duplicated, no space after the comma) so the agent writing them
 * cannot spend characters on whitespace. Prints the character count of every field.
 */
import fs from "node:fs";
import path from "node:path";

const [metaDir, jsonPath] = process.argv.slice(2);
if (!metaDir || !jsonPath) {
  console.error("usage: write-locales.mjs <metadata dir> <listing.json>");
  process.exit(2);
}
const locales = JSON.parse(fs.readFileSync(path.join("tools", "aso", "locales.json"), "utf8")).locales.map((l) => l.code);
const listing = JSON.parse(fs.readFileSync(jsonPath, "utf8"));
const fields = ["name", "subtitle", "keywords", "promotional_text", "description", "release_notes"];
const copied = ["privacy_url", "support_url"];
const chars = (s) => [...s].length;

let bad = 0;
for (const [code, entry] of Object.entries(listing)) {
  if (!locales.includes(code)) { console.error(`${code}: not in tools/aso/locales.json`); bad++; continue; }
  if (code === "en-US") { console.error("en-US is the source; this script does not overwrite it"); bad++; continue; }
  const dir = path.join(metaDir, code);
  fs.mkdirSync(dir, { recursive: true });
  for (const f of fields) {
    let v = entry[f];
    if (v === undefined || v === null) { console.error(`${code}: ${f} is missing`); bad++; continue; }
    v = String(v).replace(/\r\n/g, "\n").trim();
    if (f === "keywords") {
      const seen = new Set();
      v = v.split(",").map((k) => k.trim().toLowerCase()).filter((k) => k && !seen.has(k) && seen.add(k)).join(",");
    }
    fs.writeFileSync(path.join(dir, `${f}.txt`), v);
    console.log(`  ${code}/${f}.txt  ${chars(v)}`);
  }
  for (const f of copied) {
    const src = path.join(metaDir, "en-US", `${f}.txt`);
    if (!fs.existsSync(src)) { console.error(`${code}: cannot copy ${f}, en-US has none`); bad++; continue; }
    fs.writeFileSync(path.join(dir, `${f}.txt`), fs.readFileSync(src, "utf8").trim());
  }
}
if (bad) { console.error(`${bad} problem(s)`); process.exit(1); }
