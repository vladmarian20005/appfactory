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

const release = path.join(app, "store", "release.json");
const isGame = fs.existsSync(release) && /"GAMES"/.test(fs.readFileSync(release, "utf8"));

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
// There is no exception, a share card included. `ShareImage.render` pins Dynamic Type to
// `.large` for the render, so `scaledFont` on a card's fixed canvas draws at exactly the size
// it asks for and cannot overflow the frame.
//
// This used to exempt any file containing `ShareImage.render`, and judged a `-> Font` helper by
// where it was called. `compliance.sh` never had either subtlety: it failed a frozen size
// anywhere under `ios/`. So an app could satisfy this file, and TASTE.md, and still be unable
// to pass the gate — which is exactly what happened to language-drills on 12 Sep 2026, and the
// build agent was right that it had no legal move. Both gates now read the same line, and this
// one reads it at build time instead of six stages later.
const frozen = /\.system\(size:/;

each(frozen, (where, line) => {
  tell("FAIL", "frozen-type", `a frozen point size — it will not scale with Dynamic Type; use scaledFont(size:) or brandDisplay(size:): ${line.slice(0, 80)}`, where);
});

// ── The second session ───────────────────────────────────────────────────────
// These are the tells of an app nobody opens twice. Nothing downstream of the build could
// see them before: a screenshot of level 40 and a screenshot of level 400 are the same
// screenshot, so a flat game passed every gate the factory had. Added 12 Sep 2026 with
// TASTE.md's "The second session".

// Content picked by `% count` repeats verbatim and never ramps. Quizday holds 30 rounds and
// deals `dayNumber % rounds.count`, so day 31 is day 1 again, in the same order, forever.
// Named collections only — a modulo over a palette or a frame index is fine.
// Two spellings, because the first one it was written to catch — quizday's — binds the length
// to a local first (`let count = shared.rounds.count` … `n % count`) and slips a grep for
// `% rounds.count` by one variable.
const contentNames = "round|question|level|item|card|pack|puzzle|word|prompt|challenge|task|verse|clue";
const content = new RegExp(`%\\s*\\w*(${contentNames})s?(\\.count|\\.length)|%\\s*(count|total|\\w+(Count|Total))\\b`, "i");
each(content, (where, line) =>
  tell("FAIL", "content-modulo", `content chosen by modulo over a fixed list — it repeats verbatim and never gets harder: ${line.trim().slice(0, 90)}`, where));

// Where the ladder stops climbing, computed from the dials the same way `Ladder.flattensAt`
// computes it, because the rung it stops on is the rung players leave on. 150 is about five
// months at a level a day; Tidepour's original curve stopped at 36.
//
// This does not ask for a dial with no ceiling. Rebuilding Tidepour against that rule showed
// it forces a lie: a puzzle whose every board is solver-verified has a hardest board, and an
// open dial only means demanding solutions no board of that shape contains.
const REACH = 150;
if (has(/\bLadder\(/)) {
  const dials = [];
  each(/(?:\.init|Ladder\.Dial)\(\s*"([^"]+)"/, (where, line) => {
    const num = (key) => {
      const m = line.match(new RegExp(`\\b${key}:\\s*(-?\\d+)`));
      return m ? Number(m[1]) : null;
    };
    dials.push({ name: line.match(/"([^"]+)"/)[1], where, from: num("from"), by: num("by") ?? 1,
                 every: num("every") ?? 1, opensAt: num("opensAt") ?? 1, ceiling: num("ceiling") });
  });
  const open = dials.some((d) => d.ceiling === null);
  // A ceiling written as a constant rather than a literal (`ceiling: Board.maxCapacity`) reads
  // as null here, so only judge a ladder every dial of which parsed.
  const parsed = dials.filter((d) => d.from !== null && !/ceiling:\s*[A-Za-z_]/.test(d.where ?? ""));
  if (dials.length && !open) {
    const raw = files.flatMap((f) => f.lines).join("\n");
    const symbolic = /ceiling:\s*[A-Za-z_]/.test(raw);
    if (!symbolic && parsed.length === dials.length) {
      const flattensAt = Math.max(...dials.map((d) =>
        d.opensAt + d.every * Math.ceil((d.ceiling - d.from) / d.by)));
      if (flattensAt < REACH) {
        tell("FAIL", "flat-ladder", `the ladder stops changing the game at rung ${flattensAt}; nothing after that is different (Ladder.climbs(through: ${REACH}))`);
      }
    }
  }
}

// The app decides what to serve next without consulting anything the player has done.
const play = /\bLadder\(|\bMastery[<(]|\bRun\(\)|\bEarned\(/;
if (!has(play)) {
  const message = "nothing decides what comes next from what the player has done: no Ladder, Mastery, Run or Earned anywhere, so every session is the first session";
  if (isGame) tell("FAIL", "no-second-session", message);
  else tell("WARN", "no-second-session", `${message} — for a utility, show what deepens as the data piles up`);
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
if (isGame && !has(/Tones\.shared/)) {
  tell("WARN", "silent-game", "a game with no sound: use Tones, or say in DESIGN.md why it is silent");
}

// A difficulty that is stored and shown and never read. Quizday carries the word 332 times —
// on every one of 300 bundled questions — and nothing anywhere compares one.
// Reading it means comparing, sorting, filtering or switching on it — not carrying it through
// an initialiser, which is how the first version of this check talked itself out of firing.
const readsDifficulty = /difficulty\s*(==|!=|<|>|<=|>=)|(sorted|filter|first|drop|prefix|contains|allSatisfy|max|min|partition)\s*[({][^\n]*difficulty|switch\s+\w*\.?\w*[Dd]ifficulty/i;
if (has(/\bdifficulty\b/i) && !has(readsDifficulty)) {
  tell("WARN", "metadata-difficulty", "a `difficulty` the app stores and shows but never compares: nothing reads it to decide what the player gets next");
}
// Every door in the app is the paywall. A paywall is a fine door; it cannot be the only one.
if (has(/[Uu]nlock/) && !has(/\bEarned\(|\bearned\b/)) {
  tell("WARN", "paid-unlocks-only", "every unlock in the app is a purchase: give the player at least one thing that arrives for playing well (Earned)");
}
each(/"[^"]*\b(come back tomorrow|see you tomorrow|check back tomorrow)\b[^"]*"/i, (where, line) =>
  tell("WARN", "dead-end", `the session ends on a dead end — name what is waiting instead: ${line.trim().slice(0, 90)}`, where));
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
