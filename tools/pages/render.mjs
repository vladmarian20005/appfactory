#!/usr/bin/env node
/**
 * Render an HTML page to PNG so it can be looked at rather than guessed at.
 *
 *   node tools/pages/render.mjs <page.html> [out.png] [width]
 *
 * Writes a full-height capture at the given viewport width (default 1280) and, when no
 * explicit width is given, a second capture at 430 — an iPhone's width — as <out>-mobile.png.
 * Then Read the PNG. A landing page nobody has looked at is a guess.
 *
 * `browse` only exists on one laptop, so it cannot be what checks a page in CI. This uses the
 * Playwright already in package.json: WebKit where it is installed, because on macOS it
 * resolves `ui-serif` to New York and `ui-rounded` to SF Rounded — the faces a brand page sets
 * itself in. Chromium resolves neither and would quietly fall back to Helvetica, which is the
 * difference between a page wearing the app's brand and a page wearing a house style.
 */
import fs from "node:fs";
import path from "node:path";
import { pathToFileURL } from "node:url";
import { chromium, webkit } from "playwright";

const [file, outArg, widthArg] = process.argv.slice(2);
if (!file) {
  console.error("usage: render.mjs <page.html> [out.png] [width]");
  process.exit(1);
}
if (!fs.existsSync(file)) {
  console.error(`no such file: ${file}`);
  process.exit(1);
}

const out = outArg ?? file.replace(/\.html$/, ".png");
const widths = widthArg ? [Number(widthArg)] : [1280, 430];

async function launch() {
  try {
    return { browser: await webkit.launch(), engine: "webkit" };
  } catch {
    console.warn("render: WebKit is not installed; falling back to Chromium, which cannot resolve ui-serif");
    return { browser: await chromium.launch(), engine: "chromium" };
  }
}

const { browser, engine } = await launch();
let failed = 0;
try {
  for (const [i, width] of widths.entries()) {
    const context = await browser.newContext({ viewport: { width, height: 1000 }, deviceScaleFactor: 2 });
    const page = await context.newPage();
    const problems = [];
    page.on("pageerror", (e) => problems.push(`page error: ${e.message}`));
    // A missing screenshot or art file is the failure this catches: the page still renders,
    // just with a hole in it, and a hole is easy to miss in a long capture.
    page.on("requestfailed", (r) => problems.push(`failed request: ${r.url()}`));

    await page.goto(pathToFileURL(path.resolve(file)).href, { waitUntil: "load" });
    await page.evaluate(() => document.fonts.ready);

    const dest = i === 0 ? out : out.replace(/\.png$/, "-mobile.png");
    await page.screenshot({ path: dest, fullPage: true });
    const { height } = await page.evaluate(() => ({ height: document.body.scrollHeight }));
    console.log(`${dest}  ${width}x${height}  ${engine}`);
    for (const p of problems) {
      console.error(`  ${p}`);
      failed++;
    }
    await context.close();
  }
} finally {
  await browser.close();
}

process.exit(failed ? 1 : 0);
