#!/usr/bin/env node
// Writes design/art/*.svg and design/icon.svg from art.js, so every piece of art is drawn by
// the same cards.js the mocks use. Run from the repo root:
//
//   node apps/solitaire/design/make-art.mjs
//
// Then render them: node tools/design/art.mjs apps/solitaire/design/art/desk.svg <imageset> --width 300
// and node tools/icon.mjs apps/solitaire/design/icon-1024.png --svg apps/solitaire/design/icon.svg
import fs from "node:fs";
import path from "node:path";
import vm from "node:vm";
import { fileURLToPath } from "node:url";

const here = path.dirname(fileURLToPath(import.meta.url));
// cards.js and art.js are browser scripts (the mocks load them with <script>), so run them
// the way a page would: in one context where `self` is the global.
const ctx = vm.createContext({});
ctx.self = ctx;
for (const f of ["cards.js", "art.js"]) vm.runInContext(fs.readFileSync(path.join(here, f), "utf8"), ctx, { filename: f });
const Art = ctx.Art;

const artDir = path.join(here, "art");
fs.mkdirSync(artDir, { recursive: true });
for (const name of ["desk", "fans", "diary", "drawer"]) {
  const file = path.join(artDir, `${name}.svg`);
  fs.writeFileSync(file, Art[name]() + "\n");
  console.log(`ok   ${path.relative(process.cwd(), file)}`);
}
const icon = path.join(here, "icon.svg");
fs.writeFileSync(icon, Art.icon() + "\n");
console.log(`ok   ${path.relative(process.cwd(), icon)}`);
