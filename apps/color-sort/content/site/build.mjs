// Builds apps/color-sort/content/site/index.html from page.html.
//
//   node apps/color-sort/content/site/build.mjs
//
// app-content publishes index.html and nothing else (it copies the one file into
// starhiveconcept-site), so a page that points at hero.jpg or shots/01.jpg ships with every
// picture broken. Every local src in page.html is inlined here instead: the drawn art straight
// from design/art/, the composed store screenshots and the hero as JPEG, the icon as PNG.
//
//   src="art-<name>.svg"   design/art/<name>.svg
//   src="shots/NN.jpg"     store/screenshots/en-US/NN.png, cached as shots/NN.jpg
//   src="hero.jpg"         the bare board, kept as hero.jpg (no store caption over it)
//   src="icon.png"         design/icon-1024.png, cached as icon.png
import { execFileSync } from "node:child_process";
import { mkdirSync, readFileSync, writeFileSync, existsSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const here = dirname(fileURLToPath(import.meta.url));
const app = join(here, "..", "..");
mkdirSync(join(here, "shots"), { recursive: true });

function sips(format, width, src, out, quality) {
  if (existsSync(out)) return;
  const q = quality ? ["-s", "formatOptions", String(quality)] : [];
  execFileSync("sips", ["-s", "format", format, ...q, "--resampleWidth", String(width), src,
    "--out", out], { stdio: "ignore" });
}

const data = (mime, file) => `data:${mime};base64,${readFileSync(file).toString("base64")}`;

function inline(path) {
  let m;
  if ((m = path.match(/^art-([a-z-]+)\.svg$/))) {
    // The XML comments describe compositing for the app, not the page.
    const svg = readFileSync(join(app, "design", "art", `${m[1]}.svg`), "utf8")
      .replace(/<!--[\s\S]*?-->/g, "");
    return `data:image/svg+xml;base64,${Buffer.from(svg).toString("base64")}`;
  }
  if ((m = path.match(/^shots\/(\d\d)\.jpg$/))) {
    // The strip draws a shot 232 px wide; 480 covers a 2x screen.
    const out = join(here, path);
    sips("jpeg", 480, join(app, "store", "screenshots", "en-US", `${m[1]}.png`), out, 70);
    return data("image/jpeg", out);
  }
  if (path === "icon.png") {
    const out = join(here, "icon.png");
    sips("png", 256, join(app, "design", "icon-1024.png"), out);
    return data("image/png", out);
  }
  if (path === "hero.jpg") return data("image/jpeg", join(here, "hero.jpg"));
  throw new Error(`page.html points at ${path}, which build.mjs does not know how to inline`);
}

let html = readFileSync(join(here, "page.html"), "utf8");
html = html.replace(/(src|href)="(?!https?:|#|data:|mailto:)([^"]+\.(?:svg|jpg|png))"/g,
  (_, attr, path) => `${attr}="${inline(path)}"`);

const left = html.match(/(?:src|href)="(?!https?:|#|data:|mailto:)[^"]+\.(?:svg|jpg|png)"/);
if (left) throw new Error(`left a relative asset: ${left[0]}`);
writeFileSync(join(here, "index.html"), html);
console.log(`index.html ${(html.length / 1024).toFixed(0)} KB`);
