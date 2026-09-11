#!/usr/bin/env node
/**
 * Find the mechanical signs of a template app in an app's code: the slop tells in TASTE.md
 * that can be seen without looking at a screen.
 *
 *   node tools/design/tells.mjs <slug> [--strict] [--json]
 *
 * FAIL is a tell TASTE.md fails outright. WARN is a smell the critic confirms or dismisses
 * from the screenshots. --strict exits 1 on any FAIL; app-polish runs it that way, so a
 * lenient critique cannot pass an app that is still wearing the kit's gray.
 *
 * It reads code, so it can be fooled; it is a tripwire, not the judge. The critic is.
 */
import fs from "node:fs";
import path from "node:path";

const argv = process.argv.slice(2);
const slug = argv.find((a) => !a.startsWith("--"));
const strict = argv.includes("--strict");
const asJson = argv.includes("--json");
if (!slug) {
  console.error("usage: tells.mjs <slug> [--strict] [--json]");
  process.exit(2);
}

const app = path.join("apps", slug);
const src = path.join(app, "ios", "App");
if (!fs.existsSync(src)) {
  console.error(`tells.mjs: no ${src}`);
  process.exit(2);
}

function walk(dir) {
  return fs.readdirSync(dir, { withFileTypes: true }).flatMap((e) => {
    const p = path.join(dir, e.name);
    if (e.isDirectory()) return e.name.endsWith(".xcassets") ? [] : walk(p);
    return e.name.endsWith(".swift") ? [p] : [];
  });
}

// Code lines only: a comment that says "not systemGroupedBackground" is not a tell.
const files = walk(src).map((file) => ({
  file,
  name: path.basename(file),
  lines: fs.readFileSync(file, "utf8").split("\n").map((l) => (l.trim().startsWith("//") ? "" : l)),
}));
const all = files.flatMap((f) => f.lines).join("\n");
const has = (re) => re.test(all);

const tells = [];
const tell = (level, id, message, where) => tells.push({ level, id, message, where: where ?? null });
const each = (re, fn, filter = () => true) => {
  for (const f of files) {
    if (!filter(f)) continue;
    f.lines.forEach((line, i) => {
      if (re.test(line)) fn(`${f.file}:${i + 1}`, line.trim(), f, i);
    });
  }
};

// ── Hard tells ───────────────────────────────────────────────────────────────
if (!fs.existsSync(path.join(app, "DESIGN.md"))) {
  tell("FAIL", "no-direction", "no DESIGN.md: the app was built without a design direction");
}
if (!fs.existsSync(path.join(app, "design", "icon.svg"))) {
  tell("FAIL", "undrawn-icon", "no design/icon.svg: the icon was not drawn (a glyph on a gradient says nothing)");
}
if (has(/Brand\.factoryDefault/) || !has(/\.brand\(/)) {
  tell("FAIL", "kit-default-brand", "the app wears the kit's default brand; paste DESIGN.md's tokens into AppBrand and apply .brand(AppBrand.brand) at the root");
}
each(/\.systemGroupedBackground|secondarySystemGroupedBackground|tertiarySystemGroupedBackground|Color\(\.systemBackground\)/, (where, line) =>
  tell("FAIL", "gray-canvas", `system gray as the canvas or a card: ${line.slice(0, 90)}`, where));

const pitch = /"[^"]*\b(no ads|ad[- ]free|no timer|no lives|no coins|no currency|no in-app currency|nothing to buy|nothing runs out|nothing to run out|nothing here expires|never an ad)\b[^"]*"/i;
// VoiceOver text is allowed to explain; a hint often continues onto the next line.
const spoken = (f, i) => /accessibility/i.test(f.lines[i] + (f.lines[i - 1] ?? ""));
each(pitch, (where, line, f, i) => {
  if (spoken(f, i)) return;
  tell("FAIL", "pitch-in-product", `the product repeats the store pitch: ${line.slice(0, 100)}`, where);
}, (f) => f.name !== "AppInfo.swift");

const motion = /withMotion|withAnimation|\.animation\(|\.transition\(|popIn|matchedGeometryEffect|keyframeAnimator|phaseAnimator|confetti\(|CountUp|contentTransition|\.spring\(|symbolEffect|ambientFloat|breathing\(/;
if (!has(motion)) tell("FAIL", "nothing-moves", "no motion anywhere: state changes jump");

if (!has(/confetti\(|CountUp\(|Haptics\.celebrate|Tones\.shared/)) {
  tell("FAIL", "no-reward", "the loop's win uses none of confetti, CountUp, Haptics.celebrate or Tones: finishing is not a moment");
}

// ── Smells ───────────────────────────────────────────────────────────────────
each(/presentationDetents\(\[\.medium\]\)/, (where, line, f) => {
  const text = f.lines.join("\n");
  if (/clear|result|won|win|score|complete|finish/i.test(text)) {
    tell("WARN", "win-in-sheet", "a medium sheet in a file about results: is the win a sheet with a checkmark?", where);
  }
});
each(/"[^"]*\b[Tt]ap (a|the|to|any|on)\b[^"]*"/, (where, line, f, i) => {
  if (spoken(f, i)) return;
  tell("WARN", "ui-explained", `the UI explained in text: ${line.slice(0, 100)}`, where);
});
each(/scaledFont\(size:\s*(\d+)/, (where, line, f, i) => {
  const size = Number(line.match(/scaledFont\(size:\s*(\d+)/)[1]);
  const before = f.lines.slice(Math.max(0, i - 4), i + 1).join("\n");
  if (size >= 56 && /Image\(systemName:/.test(before)) {
    tell("WARN", "symbol-hero", `an SF Symbol at ${size}pt standing in for art`, where);
  }
});
if (!has(/brandDisplay\(|scaledFont\(size:\s*([5-9]\d|\d{3})/)) {
  tell("WARN", "no-display-type", "nothing is set bigger than a text style: no hero type anywhere");
}
const info = files.find((f) => f.name === "AppInfo.swift");
if (info && /OnboardingPage\(symbol:/.test(info.lines.join("\n")) && !/art:/.test(info.lines.join("\n"))) {
  tell("WARN", "symbol-onboarding", "onboarding pages are SF Symbols: give them art with OnboardingPage(title:subtitle:art:)");
}
if (has(/PaywallView\(/) && !has(/hero:/)) tell("WARN", "paywall-no-hero", "the paywall has no hero art");
if (has(/ShareLink\(/) && !has(/ShareImage/)) tell("WARN", "text-share", "the result shares as text, not as an image (ShareImage)");
const release = path.join(app, "store", "release.json");
if (fs.existsSync(release) && /"GAMES"/.test(fs.readFileSync(release, "utf8")) && !has(/Tones\.shared/)) {
  tell("WARN", "silent-game", "a game with no sound: use Tones, or say in DESIGN.md why it is silent");
}
if (has(/\.easeOut\(duration: 0\.1\d?\)|\.easeInOut\(duration: 0\.1\d?\)/) && !has(/spring|Motion\./)) {
  tell("WARN", "ease-only", "the only motion is a short ease: nothing has weight");
}

const hard = tells.filter((t) => t.level === "FAIL").length;
const soft = tells.length - hard;

if (asJson) {
  console.log(JSON.stringify({ slug, hard, soft, tells }, null, 2));
} else {
  console.log(`tells: ${slug}`);
  for (const t of tells) console.log(`  ${t.level.padEnd(4)}  ${t.id.padEnd(18)} ${t.message}${t.where ? `\n        ${t.where}` : ""}`);
  console.log(`${hard} hard tell(s), ${soft} smell(s)`);
}
process.exit(strict && hard > 0 ? 1 : 0);
