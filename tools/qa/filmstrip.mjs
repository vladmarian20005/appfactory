#!/usr/bin/env node
/**
 * Lay frames out as one image, so a reader who can only look at pictures can see motion.
 *
 *   node tools/qa/filmstrip.mjs <out.png> <frame.png> [...]
 *
 * Frames are shrunk to about 330px wide and placed left to right, top to bottom, four to a
 * row, in the order given. `tools/sim.sh frames` names them so a glob sorts correctly.
 */
import fs from "node:fs";
import { PNG } from "pngjs";

const [out, ...frames] = process.argv.slice(2);
if (!out || frames.length === 0) {
  console.error("usage: filmstrip.mjs <out.png> <frame.png> [...]");
  process.exit(1);
}

const TARGET = 330;
const GAP = 16;
const COLS = Math.min(4, frames.length);

// Box filter by an integer factor: cheap, and sharp enough to read a screen at this size.
function shrink(png) {
  const f = Math.max(1, Math.round(png.width / TARGET));
  const w = Math.floor(png.width / f);
  const h = Math.floor(png.height / f);
  const small = new PNG({ width: w, height: h });
  for (let y = 0; y < h; y++) {
    for (let x = 0; x < w; x++) {
      let r = 0, g = 0, b = 0;
      for (let dy = 0; dy < f; dy++) {
        for (let dx = 0; dx < f; dx++) {
          const i = ((y * f + dy) * png.width + (x * f + dx)) * 4;
          r += png.data[i]; g += png.data[i + 1]; b += png.data[i + 2];
        }
      }
      const o = (y * w + x) * 4;
      const n = f * f;
      small.data[o] = r / n; small.data[o + 1] = g / n; small.data[o + 2] = b / n; small.data[o + 3] = 255;
    }
  }
  return small;
}

const tiles = frames.map((f) => shrink(PNG.sync.read(fs.readFileSync(f))));
const tw = Math.max(...tiles.map((t) => t.width));
const th = Math.max(...tiles.map((t) => t.height));
const rows = Math.ceil(tiles.length / COLS);
const sheet = new PNG({ width: COLS * tw + (COLS + 1) * GAP, height: rows * th + (rows + 1) * GAP });
for (let i = 0; i < sheet.data.length; i += 4) {
  sheet.data[i] = 24; sheet.data[i + 1] = 24; sheet.data[i + 2] = 28; sheet.data[i + 3] = 255;
}
tiles.forEach((t, n) => {
  const ox = GAP + (n % COLS) * (tw + GAP);
  const oy = GAP + Math.floor(n / COLS) * (th + GAP);
  PNG.bitblt(t, sheet, 0, 0, t.width, t.height, ox, oy);
});
fs.writeFileSync(out, PNG.sync.write(sheet, { colorType: 2 }));
console.log(`filmstrip: ${frames.length} frame(s) → ${out}  ${sheet.width}x${sheet.height}`);
