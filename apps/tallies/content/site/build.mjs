#!/usr/bin/env node
/**
 * Build Tallies' landing page as one self-contained file.
 *
 *   node apps/tallies/content/site/build.mjs
 *
 * app-content publishes only index.html to starhiveconcept-site, so a page that pointed at
 * sibling files would arrive with every image broken. Everything the page shows is therefore
 * inlined: the drawn art and the icon from design/, and the composed store screenshots,
 * re-encoded as small JPEGs with `sips` (macOS) into content/raw/site, which git ignores.
 *
 * page.html is the source. Each {{name}} in it becomes a data: URI.
 */
import fs from "node:fs";
import path from "node:path";
import { execFileSync } from "node:child_process";
import { fileURLToPath } from "node:url";

const here = path.dirname(fileURLToPath(import.meta.url));
const app = path.resolve(here, "../..");
const tmp = path.join(app, "content/raw/site");
fs.mkdirSync(tmp, { recursive: true });

const uri = (file, type) => `data:${type};base64,${fs.readFileSync(file).toString("base64")}`;

function jpeg(src, name, maxDim) {
  const out = path.join(tmp, name);
  execFileSync("sips", ["-s", "format", "jpeg", "-s", "formatOptions", "68", "-Z", String(maxDim), src, "--out", out], { stdio: "ignore" });
  return uri(out, "image/jpeg");
}

function png(src, name, maxDim) {
  const out = path.join(tmp, name);
  execFileSync("sips", ["-Z", String(maxDim), src, "--out", out], { stdio: "ignore" });
  return uri(out, "image/png");
}

const assets = {
  icon: png(path.join(app, "design/icon-1024.png"), "icon.png", 180),
  bench: uri(path.join(app, "design/art/bench.svg"), "image/svg+xml"),
  stave: uri(path.join(app, "design/art/stave.svg"), "image/svg+xml"),
  gate: uri(path.join(app, "design/art/gate.svg"), "image/svg+xml"),
  rack: uri(path.join(app, "design/art/rack.svg"), "image/svg+xml"),
};
for (const n of ["01", "02", "03", "04", "05", "06", "07"]) {
  // 1000 px tall is 460 wide: sharp at the strip's 232 css px on a 2x screen.
  assets[`shot${n}`] = jpeg(path.join(app, `store/screenshots/en-US/${n}.png`), `${n}.jpg`, 1000);
}

let html = fs.readFileSync(path.join(here, "page.html"), "utf8");
html = html.replace(/\{\{(\w+)\}\}/g, (m, k) => {
  if (!(k in assets)) throw new Error(`page.html asks for {{${k}}}, which build.mjs does not provide`);
  return assets[k];
});
fs.writeFileSync(path.join(here, "index.html"), html);
console.log(`index.html: ${(html.length / 1024).toFixed(0)} KB`);
