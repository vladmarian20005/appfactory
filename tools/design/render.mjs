#!/usr/bin/env node
/**
 * Render HTML mockups to PNG, at the size of the phone the screenshots are taken on.
 *
 *   node tools/design/render.mjs apps/<slug>/design/mock-*.html
 *
 * Writes <name>.png next to each <name>.html, at 440x956 points and 2x, which is an
 * iPhone 17 Pro Max's screen. Then Read the PNG — a mock you have not looked at is a guess.
 *
 * Mocks are how the direction stage sees a look before anyone writes Swift: palette, type,
 * hierarchy, the hero, the win. They are a target for feel, not a pixel spec. Draw iOS's own
 * chrome (status bar, tab bar, navigation bar) as iOS draws it, because the build will use the
 * real thing; everything else is yours.
 *
 * WebKit when it is installed, because on macOS it resolves `ui-rounded` (SF Rounded),
 * `ui-serif` (New York) and `ui-monospace` (SF Mono) — the faces the app will actually use.
 * Chromium otherwise, where those fall back to SF Pro. The page gets `--safe-top: 62px` and
 * `--safe-bottom: 34px` as CSS variables for the Dynamic Island and the home indicator.
 */
import fs from "node:fs";
import path from "node:path";
import { pathToFileURL } from "node:url";
import { chromium, webkit } from "playwright";

const files = process.argv.slice(2).filter((f) => f.endsWith(".html"));
if (files.length === 0) {
  console.error("usage: render.mjs <mock.html> [...]");
  process.exit(1);
}

const WIDTH = 440;
const HEIGHT = 956;

async function launch() {
  try {
    return { browser: await webkit.launch(), engine: "webkit" };
  } catch {
    return { browser: await chromium.launch(), engine: "chromium" };
  }
}

const { browser, engine } = await launch();
let failed = 0;
try {
  const context = await browser.newContext({ viewport: { width: WIDTH, height: HEIGHT }, deviceScaleFactor: 2 });
  for (const file of files) {
    if (!fs.existsSync(file)) {
      console.error(`FAIL ${file}: does not exist`);
      failed++;
      continue;
    }
    const page = await context.newPage();
    const errors = [];
    page.on("pageerror", (e) => errors.push(e.message));
    await page.goto(pathToFileURL(path.resolve(file)).href, { waitUntil: "load" });
    await page.addStyleTag({ content: ":root{--safe-top:62px;--safe-bottom:34px}" });
    await page.evaluate(() => document.fonts.ready);
    const out = file.replace(/\.html$/, ".png");
    await page.screenshot({ path: out, clip: { x: 0, y: 0, width: WIDTH, height: HEIGHT } });
    await page.close();
    console.log(`ok   ${out}  (${engine}${errors.length ? `, ${errors.length} script error(s): ${errors[0]}` : ""})`);
  }
} finally {
  await browser.close();
}
process.exit(failed ? 1 : 0);
