// Builds apps/language-drills/content/site/index.html from page.html.
//
//   node apps/language-drills/content/site/build.mjs
//
// app-content publishes index.html and nothing else (it copies the one file into
// starhiveconcept-site), so every asset is inlined: the drawn art from design/art/, the
// composed store screenshots and the icon. The placeholders in page.html are
// {{art:<name>}}, {{shot:<NN>}} and {{icon}}.
//
// The art goes in as an <img> data URI rather than inline <svg>: kept-wall and the-bench
// both define gradients with the same ids, and two inline SVGs on one page would share them.
import { execFileSync } from "node:child_process";
import { mkdirSync, readFileSync, writeFileSync, existsSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const here = dirname(fileURLToPath(import.meta.url));
const app = join(here, "..", "..");
const cache = join(here, "shots");
mkdirSync(cache, { recursive: true });

// 600 px wide is the 340 px a shot is drawn at, at about 2x; the page comes out near 1 MB.
function jpeg(src, out, width, quality = 70) {
  if (!existsSync(out)) {
    execFileSync("sips", ["-s", "format", "jpeg", "-s", "formatOptions", String(quality),
      "--resampleWidth", String(width), src, "--out", out], { stdio: "ignore" });
  }
  return `data:image/jpeg;base64,${readFileSync(out).toString("base64")}`;
}

function png(src, out, width) {
  if (!existsSync(out)) {
    execFileSync("sips", ["-s", "format", "png", "--resampleWidth", String(width), src,
      "--out", out], { stdio: "ignore" });
  }
  return `data:image/png;base64,${readFileSync(out).toString("base64")}`;
}

function art(name) {
  // Drop the XML comments: they describe compositing for the app, not for a visitor.
  const svg = readFileSync(join(app, "design", "art", `${name}.svg`), "utf8")
    .replace(/<!--[\s\S]*?-->/g, "")
    .replace(/\n\s*\n/g, "\n")
    .trim();
  return `data:image/svg+xml;base64,${Buffer.from(svg).toString("base64")}`;
}

let html = readFileSync(join(here, "page.html"), "utf8");
html = html.replace(/\{\{art:([a-z-]+)\}\}/g, (_, n) => art(n));
html = html.replace(/\{\{shot:(\d\d)\}\}/g, (_, n) =>
  jpeg(join(app, "store", "screenshots", "en-US", `${n}.png`), join(cache, `${n}.jpg`), 600));
html = html.replace(/\{\{icon\}\}/g, () =>
  png(join(app, "design", "icon-1024.png"), join(here, "icon.png"), 180));

const left = html.match(/\{\{[^}]+\}\}/);
if (left) throw new Error(`unfilled placeholder ${left[0]}`);
writeFileSync(join(here, "index.html"), html);
console.log(`index.html ${(html.length / 1024).toFixed(0)} KB`);
