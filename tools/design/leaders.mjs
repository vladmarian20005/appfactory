#!/usr/bin/env node
/**
 * Download the App Store screenshots of the apps a new one competes with, to look at.
 *
 *   node tools/design/leaders.mjs <outdir> "<App Name>" ["<App Name>" ...]
 *
 * The direction stage reads these before it decides on a look: to see the category's
 * clichés so the new app is visibly not one of them, and to see the polish bar it has to
 * clear. They are other people's work — write them outside the repository ($RUNNER_TEMP),
 * never commit them, never copy them.
 *
 * Uses the public iTunes Search API; no key. An app that is not found is reported and skipped.
 */
import fs from "node:fs";
import path from "node:path";

const [outdir, ...names] = process.argv.slice(2);
if (!outdir || names.length === 0) {
  console.error('usage: leaders.mjs <outdir> "<App Name>" [...]');
  process.exit(1);
}
fs.mkdirSync(outdir, { recursive: true });

const slug = (s) => s.toLowerCase().replace(/[^a-z0-9]+/g, "-").replace(/^-|-$/g, "").slice(0, 40);

async function fetchRetry(url, tries = 3) {
  for (let i = 1; ; i++) {
    try {
      const res = await fetch(url, { headers: { "user-agent": "appfactory-design/1.0" } });
      if (res.ok) return res;
      if (i >= tries) throw new Error(`HTTP ${res.status}`);
    } catch (e) {
      if (i >= tries) throw e;
    }
    await new Promise((r) => setTimeout(r, 800 * i));
  }
}

let saved = 0;
for (const name of names) {
  const url = `https://itunes.apple.com/search?${new URLSearchParams({ term: name, entity: "software", country: "us", limit: "5" })}`;
  let results;
  try {
    results = (await (await fetchRetry(url)).json()).results ?? [];
  } catch (e) {
    console.error(`skip ${name}: search failed (${e.message})`);
    continue;
  }
  const want = name.toLowerCase();
  const hit = results.find((r) => r.trackName?.toLowerCase().startsWith(want.split(":")[0])) ?? results[0];
  if (!hit) {
    console.error(`skip ${name}: not found`);
    continue;
  }
  const base = slug(hit.trackName);
  const shots = (hit.screenshotUrls ?? []).slice(0, 4);
  const assets = [["icon", hit.artworkUrl512], ...shots.map((u, i) => [`${i + 1}`, u])].filter(([, u]) => u);
  for (const [label, u] of assets) {
    try {
      const buf = Buffer.from(await (await fetchRetry(u)).arrayBuffer());
      const ext = path.extname(new URL(u).pathname) || ".jpg";
      const file = path.join(outdir, `${base}-${label}${ext}`);
      fs.writeFileSync(file, buf);
      console.log(`ok   ${file}`);
      saved++;
    } catch (e) {
      console.error(`skip ${base}-${label}: ${e.message}`);
    }
  }
}
console.log(`\n${saved} image(s) in ${outdir}`);
