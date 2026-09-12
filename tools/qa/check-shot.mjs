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
 *   · an image whose content sits in one small part of the frame, i.e. an empty app window
 *
 * It asks "did a screen render", never "is this screen busy enough". The distinction matters
 * because it got this wrong once, expensively. The old rule failed any capture where fewer
 * than 4% of pixels differed from the background colour, which is not a property of an
 * unrendered screen — it is a property of a calm one. Tidepour's sparest screens tripped it
 * while its dense ones passed, so the same app produced "blank" captures on a different
 * screen each run; the answer at the time was to wait longer, which could not have helped,
 * because nothing was ever going to draw more pixels. Measured across every real capture in
 * the repository, a rendered screen occupies 68-123 of 128 cells and a minimal one still
 * occupies 30, against 0 for a window that never drew — so occupancy separates the two
 * cleanly and density does not separate them at all.
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

// Below this many distinct coarse colours the image is treated as flat.
const MIN_DISTINCT = Number(process.env.QA_MIN_DISTINCT ?? 12);
// Cells of the frame (below the status bar) that must contain something other than the
// background. 8 of 128 is a twelfth of the screen; the sparsest real capture measured 30.
const MIN_CELLS = Number(process.env.QA_MIN_CELLS ?? 8);
// A backstop for an image that is uniform but for a speck: a rendered screen always clears
// this by an order of magnitude. It is deliberately far below any real design — a calm screen
// is not an unrendered one, and this must never be the check that decides.
const MIN_VARIED = Number(process.env.QA_MIN_VARIED ?? 0.004);
const COLS = 8;
const ROWS = 16;

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
  const samples = [];
  let counted = 0;

  for (let y = startY; y < height; y += 4) {
    for (let x = 0; x < width; x += 4) {
      const i = (y * width + x) * 4;
      // Quantise to 5 bits per channel; anti-aliasing shouldn't count as variety.
      const key = ((data[i] >> 3) << 10) | ((data[i + 1] >> 3) << 5) | (data[i + 2] >> 3);
      buckets.set(key, (buckets.get(key) ?? 0) + 1);
      counted++;
      const cx = Math.min(COLS - 1, Math.floor((x / width) * COLS));
      const cy = Math.min(ROWS - 1, Math.floor(((y - startY) / (height - startY)) * ROWS));
      samples.push([cy * COLS + cx, key]);
    }
  }

  const distinct = buckets.size;
  let modalKey = null;
  let modal = 0;
  for (const [k, v] of buckets) if (v > modal) { modal = v; modalKey = k; }
  const varied = 1 - modal / counted;

  // Where the content is, not how much of it there is. A window that never drew has its
  // content nowhere; a spare screen still has a title, a control and a tab bar, spread apart.
  const cells = Array.from({ length: COLS * ROWS }, () => ({ n: 0, diff: 0 }));
  for (const [ci, key] of samples) {
    cells[ci].n++;
    if (key !== modalKey) cells[ci].diff++;
  }
  const occupied = cells.filter((c) => c.n > 0 && c.diff / c.n >= 0.02).length;

  const problems = [];
  if (distinct < MIN_DISTINCT) problems.push(`only ${distinct} distinct colours (min ${MIN_DISTINCT})`);
  if (occupied < MIN_CELLS) problems.push(`content in only ${occupied} of ${COLS * ROWS} cells (min ${MIN_CELLS})`);
  if (varied < MIN_VARIED) problems.push(`${(varied * 100).toFixed(2)}% of pixels differ from the modal colour (min ${(MIN_VARIED * 100).toFixed(1)}%)`);

  if (problems.length) {
    warn(`FAIL ${file}: ${problems.join("; ")} — looks like a blank or unrendered screen`);
    failed++;
  } else {
    say(`ok   ${file}  ${width}x${height}  ${distinct} colours  ${occupied}/${COLS * ROWS} cells  ${(varied * 100).toFixed(1)}% varied`);
  }
}

if (failed) {
  warn(`\n${failed} of ${files.length} capture(s) look blank.`);
  process.exit(1);
}
say(`\n${files.length} capture(s) look rendered.`);
