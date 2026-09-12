#!/usr/bin/env node
/**
 * Compose App Store screenshots from raw simulator captures.
 *
 *   node tools/screenshots/compose.mjs <spec.json> <outdir>
 *
 * spec.json:
 *   {
 *     "background": "#0F6A47",          // frame background, or a CSS gradient
 *     "textColor":  "#ffffff",
 *     "accent":     "#A7F3D0",          // subtitle colour
 *     "font":       "serif",            // the brand's display face: serif (New York),
 *                                       // rounded (SF Rounded), monospaced, default (SF Pro),
 *                                       // or a CSS font-family stack. Match DESIGN.md.
 *     "titleWeight":   700,             // optional; defaults to 700 for serif, 800 otherwise
 *     "titleTracking": "-0.005em",      // optional; serif defaults looser than sans
 *     "shots": [
 *       { "src": "raw/01.png", "title": "Ten questions a day", "subtitle": "No ads, nothing runs out." }
 *     ]
 *   }
 *
 * Output is 1320x2868 (6.9"), the primary iPhone size App Store Connect asks for; it scales
 * that down for every smaller device class itself. Files are written as 01.png, 02.png, …
 * into <outdir>, which must be a locale directory — `deliver` reads <path>/<locale>/*.png
 * and silently uploads nothing if the locale level is missing.
 *
 * Runs anywhere Node and Chromium run. It renders with Playwright rather than shelling out
 * to a browser binary that only exists on one laptop. Compose on macOS when you can:
 * `-apple-system` resolves to real SF Pro there, and falls back to something with different
 * metrics on Linux, which re-wraps every headline.
 */
import fs from "node:fs";
import path from "node:path";
import { chromium, webkit } from "playwright";
import { PNG } from "pngjs";

const [specPath, outDir] = process.argv.slice(2);
if (!specPath || !outDir) {
  console.error("usage: compose.mjs <spec.json> <outdir>");
  process.exit(1);
}

const W = Number(process.env.SHOT_W ?? 1320);
const H = Number(process.env.SHOT_H ?? 2868);

const spec = JSON.parse(fs.readFileSync(specPath, "utf8"));
if (!Array.isArray(spec.shots) || spec.shots.length === 0) {
  console.error(`${specPath}: "shots" must be a non-empty array`);
  process.exit(1);
}
if (spec.shots.length > 10) {
  console.error(`${specPath}: App Store Connect accepts at most 10 screenshots, got ${spec.shots.length}`);
  process.exit(1);
}

const esc = (s) =>
  String(s ?? "").replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");

fs.mkdirSync(outDir, { recursive: true });

/**
 * App Store Connect rejects images carrying an alpha channel, even a fully opaque one.
 * Chromium always writes RGBA, so re-encode as 8-bit RGB. Doing it in-process keeps this
 * working on a runner without ffmpeg.
 */
function stripAlpha(file) {
  const png = PNG.sync.read(fs.readFileSync(file));
  // pngjs keeps `data` as RGBA in memory whatever the colorType, so flatten in place at a
  // stride of 4 and let the encoder drop the channel. Writing 3 bytes per pixel here
  // desynchronises every row and produces a smeared, repeating image.
  for (let i = 0; i < png.data.length; i += 4) {
    const a = png.data[i + 3] / 255;
    png.data[i] = Math.round(png.data[i] * a + 255 * (1 - a));
    png.data[i + 1] = Math.round(png.data[i + 1] * a + 255 * (1 - a));
    png.data[i + 2] = Math.round(png.data[i + 2] * a + 255 * (1 - a));
    png.data[i + 3] = 255;
  }
  fs.writeFileSync(file, PNG.sync.write(png, { colorType: 2 }));
  return { width: png.width, height: png.height };
}

/**
 * The frame's display face.
 *
 * The store frame is where most people meet the app, and setting it in SF Pro while the app
 * itself is a newspaper in New York breaks the identity at exactly the point of sale. `font`
 * in the spec names the brand's display face the same way DESIGN.md does; the generic CSS
 * families are what WebKit resolves to the real system faces on macOS.
 */
const FACES = {
  serif: `ui-serif,"New York","Iowan Old Style",Georgia,serif`,
  rounded: `ui-rounded,"SF Pro Rounded","Avenir Next Rounded",-apple-system,sans-serif`,
  monospaced: `ui-monospace,"SF Mono",Menlo,monospace`,
  default: `-apple-system,"SF Pro Display","SF Pro Text","Helvetica Neue",Helvetica,Arial,sans-serif`,
};
const face = FACES[spec.font] ?? spec.font ?? FACES.default;
// A serif at 800 is a different typeface from a serif at 700, and New York has no 800. Let a
// brand say what it means, and default to the weight the face actually carries.
const titleWeight = spec.titleWeight ?? (spec.font === "serif" ? 700 : 800);
// Tight tracking is a grotesque's habit; it makes a text serif look squeezed.
const titleTracking = spec.titleTracking ?? (spec.font === "serif" ? "-0.005em" : "-0.025em");

function frameHTML(shot) {
  // The device mock is proportional to the canvas so the layout survives a size change.
  const deviceW = Math.round(W * 0.818);
  const deviceH = Math.round(deviceW * 2.1667);
  const top = shot.subtitle ? Math.round(H * 0.258) : Math.round(H * 0.222);
  return `<!doctype html><html><head><meta charset="utf-8"><style>
  html,body{margin:0;padding:0;background:#000}
  #frame{
    width:${W}px;height:${H}px;position:relative;overflow:hidden;
    background:${spec.background ?? "#111"};color:${spec.textColor ?? "#fff"};
    font-family:${face};
    -webkit-font-smoothing:antialiased;
  }
  .copy{position:absolute;top:${Math.round(H * 0.061)}px;left:${Math.round(W * 0.074)}px;right:${Math.round(W * 0.074)}px;text-align:center}
  h1{font-size:${Math.round(W * 0.084)}px;line-height:1.04;margin:0 0 ${Math.round(H * 0.011)}px;font-weight:${titleWeight};letter-spacing:${titleTracking}}
  p{font-size:${Math.round(W * 0.042)}px;line-height:1.3;margin:0;color:${spec.accent ?? "rgba(255,255,255,.85)"};font-weight:500}
  .device{
    position:absolute;left:50%;transform:translateX(-50%);top:${top}px;
    width:${deviceW}px;height:${deviceH}px;border-radius:${Math.round(deviceW * 0.148)}px;
    background:#0a0a0a;padding:${Math.round(deviceW * 0.026)}px;
    box-shadow:0 ${Math.round(H * 0.025)}px ${Math.round(H * 0.057)}px rgba(0,0,0,.5);
  }
  .screen{width:100%;height:100%;border-radius:${Math.round(deviceW * 0.122)}px;overflow:hidden;background:#000}
  .screen img{display:block;width:100%;height:100%;object-fit:cover;object-position:top}
  </style></head><body><div id="frame">
  <div class="copy"><h1>${esc(shot.title)}</h1>${shot.subtitle ? `<p>${esc(shot.subtitle)}</p>` : ""}</div>
  <div class="device"><div class="screen"><img src="${shot.dataURI}"></div></div>
  </div></body></html>`;
}

// WebKit where it is installed, for the same reason tools/design/render.mjs prefers it: on
// macOS it resolves `ui-serif` to New York and `ui-rounded` to SF Rounded, which is the whole
// point of setting the frame in the brand's face. Chromium resolves neither and would quietly
// fall back to Helvetica, so a brand face would be a no-op nobody noticed.
async function launch() {
  if (process.platform === "darwin" && spec.font && spec.font !== "default") {
    try {
      return { browser: await webkit.launch(), engine: "webkit" };
    } catch {
      console.warn("compose: WebKit is not installed; falling back to Chromium, which cannot resolve ui-serif or ui-rounded");
    }
  }
  return { browser: await chromium.launch(), engine: "chromium" };
}

const { browser, engine } = await launch();
console.log(`compose: ${engine}, face ${spec.font ?? "default"}`);
try {
  const page = await browser.newPage({ viewport: { width: W, height: H }, deviceScaleFactor: 1 });

  for (const [i, shot] of spec.shots.entries()) {
    const src = path.resolve(path.dirname(specPath), shot.src);
    if (!fs.existsSync(src)) throw new Error(`shot ${i + 1}: no such capture: ${src}`);
    if (!shot.title) throw new Error(`shot ${i + 1}: every shot needs a title`);
    if (shot.title.length > 40) {
      console.warn(`shot ${i + 1}: title is ${shot.title.length} chars; over 40 wraps badly`);
    }

    // Inline the capture. A file:// <img> is blocked when the page itself is set via
    // setContent, and inlining also removes any dependence on the temp file surviving.
    shot.dataURI = `data:image/png;base64,${fs.readFileSync(src).toString("base64")}`;

    await page.setContent(frameHTML(shot), { waitUntil: "load" });
    await page.evaluate(() => document.fonts.ready);

    const out = path.join(outDir, `${String(i + 1).padStart(2, "0")}.png`);
    await page.locator("#frame").screenshot({ path: out });
    const { width, height } = stripAlpha(out);
    if (width !== W || height !== H) throw new Error(`${out}: got ${width}x${height}, expected ${W}x${H}`);
    console.log(`wrote ${out}  ${width}x${height}  no alpha`);
  }
} finally {
  await browser.close();
}

console.log(`\n${spec.shots.length} screenshot(s) in ${outDir}`);
