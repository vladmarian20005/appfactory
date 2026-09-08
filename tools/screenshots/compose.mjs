#!/usr/bin/env node
/**
 * Compose App Store screenshots (6.7", 1290x2796) from raw simulator captures.
 *   node factory/tools/screenshots/compose.mjs <spec.json> <outdir>
 * spec.json:
 *   { "background": "#0F6A47", "textColor": "#ffffff", "accent": "#A7F3D0",
 *     "shots": [ { "src": "raw/01.png", "title": "Log a meal in 3 seconds", "subtitle": "No paywall on the basics." } ] }
 * Raw captures come from `factory/tools/sim.sh shot`. Titles wrap automatically; keep them under 40 characters.
 */
import fs from "node:fs";
import path from "node:path";
import { execFileSync } from "node:child_process";

const [specPath, outDir] = process.argv.slice(2);
if (!specPath || !outDir) {
  console.error("usage: compose.mjs <spec.json> <outdir>");
  process.exit(1);
}
const B = process.env.BROWSE ?? `${process.env.HOME}/.claude/skills/gstack/browse/dist/browse`;
const spec = JSON.parse(fs.readFileSync(specPath, "utf8"));
const W = 1290;
const H = 2796;
const esc = (s) => String(s ?? "").replace(/&/g, "&amp;").replace(/</g, "&lt;");
fs.mkdirSync(outDir, { recursive: true });
execFileSync(B, ["viewport", `${W}x${H}`]);

spec.shots.forEach((shot, i) => {
  const src = path.resolve(path.dirname(specPath), shot.src);
  const html = `<!doctype html><html><head><meta charset="utf-8"><style>
html,body{margin:0;background:#000}
#frame{width:${W}px;height:${H}px;background:${spec.background ?? "#111"};color:${spec.textColor ?? "#fff"};
  font-family:-apple-system,"SF Pro Display","Helvetica Neue",Inter,sans-serif;position:relative;overflow:hidden}
.copy{position:absolute;top:170px;left:96px;right:96px;text-align:center}
h1{font-size:108px;line-height:1.04;margin:0 0 30px;font-weight:800;letter-spacing:-0.025em}
p{font-size:54px;line-height:1.3;margin:0;color:${spec.accent ?? "rgba(255,255,255,.85)"}}
.device{position:absolute;left:50%;transform:translateX(-50%);top:${shot.subtitle ? 720 : 620}px;width:1080px;height:2360px;
  border-radius:160px;background:#0a0a0a;padding:28px;box-shadow:0 70px 160px rgba(0,0,0,.5)}
.screen{width:100%;height:100%;border-radius:132px;overflow:hidden;background:#000}
.screen img{display:block;width:100%;height:100%;object-fit:cover;object-position:top}
</style></head><body><div id="frame">
<div class="copy"><h1>${esc(shot.title)}</h1>${shot.subtitle ? `<p>${esc(shot.subtitle)}</p>` : ""}</div>
<div class="device"><div class="screen"><img src="file://${src}"></div></div>
</div></body></html>`;
  const htmlPath = path.join(outDir, `frame-${i + 1}.html`);
  fs.writeFileSync(htmlPath, html);
  execFileSync(B, ["goto", `file://${path.resolve(htmlPath)}`]);
  execFileSync(B, ["wait", "--load"]);
  const outPng = path.join(outDir, `${String(i + 1).padStart(2, "0")}.png`);
  execFileSync(B, ["screenshot", outPng, "--selector", "#frame"]);
  execFileSync("ffmpeg", ["-y", "-loglevel", "error", "-i", outPng, "-pix_fmt", "rgb24", outPng + ".rgb.png"]);
  fs.renameSync(outPng + ".rgb.png", outPng);
  fs.unlinkSync(htmlPath);
  console.log(`wrote ${outPng}`);
});
