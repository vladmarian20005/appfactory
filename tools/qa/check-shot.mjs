#!/usr/bin/env node
/**
 * Assert a simulator capture actually shows a rendered screen.
 *
 *   node tools/qa/check-shot.mjs <shot.png> [...]
 *
 * A screenshot of a simulator that never finished booting, or of an app that crashed on
 * launch, is a valid PNG of the right size — it is just flat. That used to pass as a green
 * build. This fails on:
 *
 *   · a near-uniform image (a black, white or single-colour screen)
 *   · an image whose content is confined to the status bar, i.e. an empty app window
 *
 * Exits non-zero and names the file, so a CI log says which screen broke.
 */
import fs from "node:fs";
import { PNG } from "pngjs";

// --quiet reports only through the exit code, so sim.sh can use this as a predicate while
// it waits for an app to finish drawing.
const quiet = process.argv.includes("--quiet");
const files = process.argv.slice(2).filter((a) => a !== "--quiet");
if (files.length === 0) {
  console.error("usage: check-shot.mjs [--quiet] <shot.png> [...]");
  process.exit(1);
}
const say = (...a) => { if (!quiet) console.log(...a); };
const warn = (...a) => { if (!quiet) console.error(...a); };

// Below this fraction of distinct coarse colours the image is treated as flat.
const MIN_DISTINCT = Number(process.env.QA_MIN_DISTINCT ?? 12);
// Fraction of pixels that must differ from the modal colour.
const MIN_VARIED = Number(process.env.QA_MIN_VARIED ?? 0.04);

let failed = 0;

for (const file of files) {
  if (!fs.existsSync(file)) {
    warn(`FAIL ${file}: does not exist`);
    failed++;
    continue;
  }

  const png = PNG.sync.read(fs.readFileSync(file));
  const { width, height, data } = png;

  // Ignore the top 6% so a rendered status bar cannot rescue an otherwise empty screen.
  const startY = Math.floor(height * 0.06);
  const buckets = new Map();
  let counted = 0;

  for (let y = startY; y < height; y += 4) {
    for (let x = 0; x < width; x += 4) {
      const i = (y * width + x) * 4;
      // Quantise to 5 bits per channel; anti-aliasing shouldn't count as variety.
      const key = ((data[i] >> 3) << 10) | ((data[i + 1] >> 3) << 5) | (data[i + 2] >> 3);
      buckets.set(key, (buckets.get(key) ?? 0) + 1);
      counted++;
    }
  }

  const distinct = buckets.size;
  const modal = Math.max(...buckets.values());
  const varied = 1 - modal / counted;

  const problems = [];
  if (distinct < MIN_DISTINCT) problems.push(`only ${distinct} distinct colours (min ${MIN_DISTINCT})`);
  if (varied < MIN_VARIED) problems.push(`${(varied * 100).toFixed(1)}% of pixels differ from the modal colour (min ${(MIN_VARIED * 100).toFixed(0)}%)`);

  if (problems.length) {
    warn(`FAIL ${file}: ${problems.join("; ")} — looks like a blank or unrendered screen`);
    failed++;
  } else {
    say(`ok   ${file}  ${width}x${height}  ${distinct} colours  ${(varied * 100).toFixed(1)}% varied`);
  }
}

if (failed) {
  warn(`\n${failed} of ${files.length} capture(s) look blank.`);
  process.exit(1);
}
say(`\n${files.length} capture(s) look rendered.`);
