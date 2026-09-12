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

// Frozen type. `.system(size:)` looks identical at the largest accessibility text size as it
// does at the default, so a display face quietly stops scaling — and neither the compliance
// grep nor a screenshot at default settings catches it. `scaledFont(size:)` and
// `brandDisplay(size:)` say the same point size and still scale.
//
// The one honest exception is a share card: `ShareImage.render` draws into an ImageRenderer at
// a fixed pixel size, outside the view hierarchy, where Dynamic Type has nothing to scale
// against. So a frozen font is allowed if — and only if — it never reaches a screen. A helper
// that returns a frozen Font is judged by where it is called, not by where it is written.
const bitmap = (f) => /ShareImage\.render|ImageRenderer\s*\(/.test(f.lines.join("\n"));
const bitmapFiles = new Set(files.filter(bitmap).map((f) => f.file));
const frozen = /\.system\(size:/;

/** The name of the `-> Font` helper this line sits inside, if it sits inside one. */
function fontHelperAt(f, i) {
  for (let j = i; j >= 0 && i - j < 12; j--) {
    const m = f.lines[j].match(/func\s+(\w+)\s*\(.*->\s*Font\b/);
    if (m) return m[1];
    // A different declaration between here and the line means we left the helper.
    if (j < i && /\bfunc\s+\w+\s*\(|\bvar\s+body\b/.test(f.lines[j])) return null;
  }
  return null;
}

/**
 * Files other than bitmap renderers that call the helper.
 *
 * Only a qualified call counts — `AppBrand.dateline(…)`, `Self.press(…)`. A bare `.dateline(…)`
 * is a view modifier chained onto a Text, and an app may well have both under one name:
 * Quizday's `.dateline(_:tracking:color:)` scales and its `AppBrand.dateline(_:)` does not,
 * which is exactly the arrangement this tell is meant to allow.
 */
function screenCallers(name) {
  const call = new RegExp(`(?:\\b[A-Z]\\w*|Self)\\.${name}\\s*\\(`);
  return files
    .filter((f) => !bitmapFiles.has(f.file) && f.lines.some((line) => call.test(line)))
    .map((f) => path.basename(f.file));
}

each(frozen, (where, line, f, i) => {
  if (bitmapFiles.has(f.file)) return;
  const helper = fontHelperAt(f, i);
  if (!helper) {
    tell("FAIL", "frozen-type", `a frozen point size on screen — it will not scale with Dynamic Type; use scaledFont(size:) or brandDisplay(size:): ${line.slice(0, 80)}`, where);
    return;
  }
  const callers = screenCallers(helper);
  if (callers.length) {
    tell("FAIL", "frozen-type", `${helper}() returns a frozen Font and is used on screen (${[...new Set(callers)].join(", ")}), so that type will not scale with Dynamic Type`, where);
  }
});

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
// The kit's own placeholder voice, which TASTE.md counts as a slop tell wherever it appears.
// Both critics asked for this independently on the first two apps: "Continue" and "Get
// started" are the first and last words an app says, and they are the template's words.
each(/OnboardingView\(/, (where, line, f) => {
  const text = f.lines.join("\n");
  if (!/nextTitle:|finishTitle:/.test(text)) {
    tell("WARN", "kit-voice-onboarding", "onboarding uses the kit's \"Continue\"/\"Get started\"; name the buttons in the app's voice with OnboardingView(nextTitle:finishTitle:)", where);
  }
});
each(/PaywallView\(/, (where, line, f) => {
  const text = f.lines.join("\n");
  if (!/\bcta:/.test(text)) {
    tell("WARN", "kit-voice-paywall", "the paywall button falls back to the kit's \"Continue\"; say what the purchase does with PaywallView(cta:)", where);
  }
});
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
