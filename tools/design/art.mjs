#!/usr/bin/env node
/**
 * Turn an SVG drawing into an image set the app can show with `Image("<Name>")`.
 *
 *   node tools/design/art.mjs <art.svg> <App/Assets.xcassets/<Name>.imageset> --width <points> [--dark <art-dark.svg>]
 *
 * For illustration that is too rich to build from SwiftUI shapes — a mascot, a hero object,
 * an empty-state scene, the paywall's picture. Draw it as SVG in apps/<slug>/design/art/,
 * render it here at @2x and @3x with a transparent background, and it ships as an ordinary
 * asset. Rendered by a browser rather than handed to the asset catalog as SVG, because
 * CoreSVG silently drops filters, masks and CSS, and a drawing that loses its glow in the
 * build but not in the mock is a bug nobody sees until the screenshot.
 *
 * Anything that animates part by part (a blinking eye, liquid that sloshes) is better built
 * in SwiftUI; a whole drawing that floats or pops is fine as an image.
 */
import fs from "node:fs";
import path from "node:path";
import { chromium } from "playwright";

const args = process.argv.slice(2);
const [svgFile, setDir] = args;
const flag = (name) => {
  const i = args.indexOf(name);
  return i === -1 ? undefined : args[i + 1];
};
const width = Number(flag("--width"));
const darkFile = flag("--dark");

if (!svgFile || !setDir || !setDir.endsWith(".imageset") || !(width > 0)) {
  console.error("usage: art.mjs <art.svg> <Name.imageset> --width <points> [--dark <art-dark.svg>]");
  process.exit(1);
}

function readSvg(file) {
  const svg = fs.readFileSync(file, "utf8").replace(/<\?xml[^>]*\?>/, "").trim();
  const box = svg.match(/viewBox\s*=\s*"([\d.\s-]+)"/i);
  if (!box) {
    console.error(`art.mjs: ${file} has no viewBox`);
    process.exit(1);
  }
  const [, , w, h] = box[1].trim().split(/\s+/).map(Number);
  return { svg, aspect: h / w };
}

const base = path.basename(setDir, ".imageset").replace(/[^A-Za-z0-9_-]/g, "").toLowerCase();
fs.mkdirSync(setDir, { recursive: true });
for (const f of fs.readdirSync(setDir)) fs.rmSync(path.join(setDir, f));

const browser = await chromium.launch();
const images = [];
try {
  const variants = [[svgFile, ""], ...(darkFile ? [[darkFile, "-dark"]] : [])];
  for (const [file, suffix] of variants) {
    const { svg, aspect } = readSvg(file);
    for (const scale of [2, 3]) {
      const page = await browser.newPage({
        viewport: { width: Math.round(width), height: Math.round(width * aspect) },
        deviceScaleFactor: scale,
      });
      await page.setContent(
        `<!doctype html><html><head><style>html,body{margin:0;background:transparent}svg{display:block;width:100vw;height:100vh}</style></head><body>${svg}</body></html>`,
      );
      const name = `${base}${suffix}@${scale}x.png`;
      await page.screenshot({ path: path.join(setDir, name), omitBackground: true });
      await page.close();
      images.push({
        idiom: "universal",
        filename: name,
        scale: `${scale}x`,
        ...(suffix ? { appearances: [{ appearance: "luminosity", value: "dark" }] } : {}),
      });
    }
  }
} finally {
  await browser.close();
}

fs.writeFileSync(path.join(setDir, "Contents.json"), JSON.stringify({ images, info: { author: "xcode", version: 1 } }, null, 2) + "\n");
console.log(`art: ${setDir}  ${images.length} image(s) at ${width}pt wide — use Image("${path.basename(setDir, ".imageset")}")`);
