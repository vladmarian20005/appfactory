// Render the landing page to PNGs so it can be read back. Playwright, not a browser
// binary that only exists on one laptop — same reason tools/screenshots/compose.mjs uses it.
//   node render-site.mjs <out-prefix> [light|dark] [width] [slice-height]
// Run from apps/<slug>/content/site.
import path from "node:path";
import { chromium } from "playwright";

const prefix = process.argv[2] ?? "/tmp/site";
const scheme = process.argv[3] ?? "light";
const width = Number(process.argv[4] ?? 1200);
const slice = Number(process.argv[5] ?? 2200);

const browser = await chromium.launch();
const page = await browser.newPage({
  viewport: { width, height: 1000 },
  deviceScaleFactor: 1,
  colorScheme: scheme,
});
await page.goto("file://" + path.resolve("index.html"), { waitUntil: "networkidle" });
const height = await page.evaluate(() => document.documentElement.scrollHeight);

for (let i = 0, y = 0; y < height; i++, y += slice) {
  const h = Math.min(slice, height - y);
  const out = `${prefix}-${String(i + 1).padStart(2, "0")}.png`;
  await page.screenshot({ path: out, fullPage: true, clip: { x: 0, y, width, height: h } });
  console.log("wrote", out, `${width}x${h}`);
}
await browser.close();
