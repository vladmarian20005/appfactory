// Builds apps/quizday/content/site/index.html from page.html.
//
//   node apps/quizday/content/site/build.mjs
//
// app-content publishes index.html and nothing else (it copies the one file into
// starhiveconcept-site), so every asset is inlined: the drawn art from design/art/ as SVG,
// the composed store screenshots and the icon as base64. The placeholders in page.html are
// {{art:<name>}}, {{shot:<NN>}} and {{icon}}.
import { execFileSync } from "node:child_process";
import { mkdirSync, readFileSync, writeFileSync, existsSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const here = dirname(fileURLToPath(import.meta.url));
const app = join(here, "..", "..");
const cache = join(here, "shots");
mkdirSync(cache, { recursive: true });

// 600 px wide is twice the widest a shot is ever drawn on the page.
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
  // Drop the XML comments (they describe compositing for the app) and give the SVG a role.
  return readFileSync(join(app, "design", "art", `${name}.svg`), "utf8")
    .replace(/<!--[\s\S]*?-->/g, "")
    .replace(/\n\s*\n/g, "\n")
    .replace("<svg ", `<svg class="art-${name}" aria-hidden="true" `)
    .trim();
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
