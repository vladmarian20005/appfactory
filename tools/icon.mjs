#!/usr/bin/env node
/**
 * Render a 1024x1024 App Store icon from a gradient and one glyph.
 *
 *   node tools/icon.mjs <out.png> "<glyph or short text>" "<css background>"
 *
 * Example:
 *   node tools/icon.mjs apps/quizday/ios/App/Assets.xcassets/AppIcon.appiconset/icon-1024.png \
 *     "10" "linear-gradient(160deg,#5B7CFA 0%,#2A3EA8 100%)"
 *
 * Apple rejects an icon with an alpha channel or with rounded corners baked in: ship a full
 * square and let iOS mask it. This writes 8-bit RGB with square corners.
 *
 * Replaces the old icon.sh, which shelled out to a browser binary that existed only on one
 * laptop and so could never run in CI.
 */
import fs from "node:fs";
import path from "node:path";
import { chromium } from "playwright";
import { PNG } from "pngjs";

const [out, glyph = "A", background = "linear-gradient(160deg,#1fbf8f 0%,#0f6a47 100%)"] =
  process.argv.slice(2);

if (!out) {
  console.error('usage: icon.mjs <out.png> "<glyph>" "<css background>"');
  process.exit(1);
}

const SIZE = 1024;
const esc = (s) => String(s).replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");

// One or two characters fill the tile; longer strings need to shrink to stay inside it.
const glyphLength = [...String(glyph)].length;
const fontSize = glyphLength <= 1 ? 560 : glyphLength === 2 ? 440 : glyphLength === 3 ? 320 : 240;

const html = `<!doctype html><html><head><meta charset="utf-8"><style>
html,body{margin:0;padding:0;background:#000}
#icon{
  width:${SIZE}px;height:${SIZE}px;background:${background};
  display:flex;align-items:center;justify-content:center;
  font-family:-apple-system,"SF Pro Rounded","SF Pro Display","Helvetica Neue",Helvetica,Arial,sans-serif;
  font-weight:800;font-size:${fontSize}px;color:#fff;letter-spacing:-0.04em;
  -webkit-font-smoothing:antialiased;
}
</style></head><body><div id="icon">${esc(glyph)}</div></body></html>`;

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
