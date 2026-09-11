#!/usr/bin/env node
/**
 * Render a 1024x1024 App Store icon.
 *
 *   node tools/icon.mjs <out.png> --svg <icon.svg>                 the icon, drawn
 *   node tools/icon.mjs <out.png> "<glyph>" "<css background>"     a glyph on a gradient
 *
 * The SVG form is the one to use. An icon is the first thing anyone sees of an app and a
 * letter or a number on a gradient says nothing about it — the first two apps shipped "10" on
 * purple and three flat bars on navy. Draw the idea instead: write the SVG with a
 * `viewBox="0 0 1024 1024"`, full-bleed (no rounded corners, iOS masks them), and keep the
 * subject inside the middle ~80% so the mask does not clip it. Gradients, filters and
 * clip paths all render. The glyph form is kept for scripts that still call it.
 *
 * Apple rejects an icon with an alpha channel or with rounded corners baked in: this writes
 * 8-bit RGB with square corners.
 *
 * Replaces the old icon.sh, which shelled out to a browser binary that existed only on one
 * laptop and so could never run in CI.
 */
import fs from "node:fs";
import path from "node:path";
import { chromium } from "playwright";
import { PNG } from "pngjs";

const args = process.argv.slice(2);
const out = args[0];
const svgAt = args.indexOf("--svg");

if (!out || (svgAt !== -1 && !args[svgAt + 1])) {
  console.error('usage: icon.mjs <out.png> --svg <icon.svg>\n       icon.mjs <out.png> "<glyph>" "<css background>"');
  process.exit(1);
}

const SIZE = 1024;
const esc = (s) => String(s).replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");

let body;
if (svgAt !== -1) {
  const file = args[svgAt + 1];
  if (!fs.existsSync(file)) {
    console.error(`icon.mjs: no such file: ${file}`);
    process.exit(1);
  }
  const svg = fs.readFileSync(file, "utf8").replace(/<\?xml[^>]*\?>/, "").trim();
  if (!/viewBox/i.test(svg)) {
    console.error(`icon.mjs: ${file} has no viewBox, so it would not scale to ${SIZE}px. Use viewBox="0 0 1024 1024".`);
    process.exit(1);
  }
  body = `<div id="icon">${svg}</div>`;
} else {
  const glyph = args[1] ?? "A";
  const background = args[2] ?? "linear-gradient(160deg,#1fbf8f 0%,#0f6a47 100%)";
  // One or two characters fill the tile; longer strings need to shrink to stay inside it.
  const glyphLength = [...String(glyph)].length;
  const fontSize = glyphLength <= 1 ? 560 : glyphLength === 2 ? 440 : glyphLength === 3 ? 320 : 240;
  body = `<div id="icon" class="glyph" style="background:${background};font-size:${fontSize}px">${esc(glyph)}</div>`;
}

const html = `<!doctype html><html><head><meta charset="utf-8"><style>
html,body{margin:0;padding:0;background:#fff}
#icon{width:${SIZE}px;height:${SIZE}px;overflow:hidden}
#icon>svg{display:block;width:${SIZE}px;height:${SIZE}px}
#icon.glyph{
  display:flex;align-items:center;justify-content:center;
  font-family:-apple-system,"SF Pro Rounded","SF Pro Display","Helvetica Neue",Helvetica,Arial,sans-serif;
  font-weight:800;color:#fff;letter-spacing:-0.04em;-webkit-font-smoothing:antialiased;
}
</style></head><body>${body}</body></html>`;

const browser = await chromium.launch();
try {
  const page = await browser.newPage({
    viewport: { width: SIZE, height: SIZE },
    deviceScaleFactor: 1,
  });
  await page.setContent(html, { waitUntil: "load" });
  await page.evaluate(() => document.fonts.ready);
  fs.mkdirSync(path.dirname(path.resolve(out)), { recursive: true });
  await page.locator("#icon").screenshot({ path: out });
} finally {
  await browser.close();
}

// Flatten to RGB. pngjs keeps `data` as RGBA whatever the colorType, so walk it at a
// stride of 4 and let the encoder drop the channel.
const png = PNG.sync.read(fs.readFileSync(out));
for (let i = 0; i < png.data.length; i += 4) {
  const a = png.data[i + 3] / 255;
  png.data[i] = Math.round(png.data[i] * a + 255 * (1 - a));
  png.data[i + 1] = Math.round(png.data[i + 1] * a + 255 * (1 - a));
  png.data[i + 2] = Math.round(png.data[i + 2] * a + 255 * (1 - a));
  png.data[i + 3] = 255;
}
fs.writeFileSync(out, PNG.sync.write(png, { colorType: 2 }));

if (png.width !== SIZE || png.height !== SIZE) {
  console.error(`${out}: got ${png.width}x${png.height}, expected ${SIZE}x${SIZE}`);
  process.exit(1);
}
console.log(`Icon written: ${out}  ${png.width}x${png.height}  no alpha`);
