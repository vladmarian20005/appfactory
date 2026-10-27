// Records the five launch clips on the booted simulator.
//
//   node apps/language-drills/content/record.mjs [01 02 …]
//
// Needs `tools/sim.sh build apps/language-drills/ios Thousand` first, and SIM_UDID (or a
// booted device). The Release .app in ios/.build is installed fresh before the first take.
// Nothing on a runner can touch the screen, so every clip is a launch flag: `-demo turn` and
// `-demo win` make the app perform the turn and the reward by itself, at the slower pace the
// app keeps for a camera; the rest open a screen. Each take is recorded raw to
// content/raw/NN-*.mov, stopped with SIGINT as recordVideo expects, and converted to a
// vertical 1080x1920 30 fps MP4 in content/clips/. The phone's 1320x2868 is scaled to the
// full 1920 height and padded with the app's lime plaster, so nothing is cropped and captions
// can sit in the margins later.
import { execFileSync, spawn } from "node:child_process";
import { mkdirSync, rmSync, existsSync, readdirSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const here = dirname(fileURLToPath(import.meta.url));
const app = join(here, "..");
const raw = join(here, "raw");
const clips = join(here, "clips");
mkdirSync(raw, { recursive: true });
mkdirSync(clips, { recursive: true });

const bundle = "com.starhiveconcept.thousand";
const booted = () => Object.values(JSON.parse(execFileSync("xcrun",
  ["simctl", "list", "devices", "booted", "-j"]).toString()).devices).flat()[0]?.udid;
const udid = process.env.SIM_UDID || booted();
if (!udid) throw new Error("no booted simulator and no SIM_UDID");

// A take is one launch and one recording. A clip is one or more takes, joined. `cut` is the
// part of the raw take kept, "start-end" in seconds: a cold launch on a runner shows the home
// screen and then a blank window for a few seconds, so every cut starts where the app has
// drawn. The cuts were measured from contact sheets of the raw takes (frames.swift).
const CLIPS = [
  { id: "01", name: "the-turn", takes: [
    // drawn at 9.0; the first turn lands ~12, then a turn and a Got it every ~4.2 s
    { args: ["-onboarded", "-sampleData", "-demo", "turn"], seconds: 34, cut: "9-33" } ] },
  { id: "02", name: "the-wall-grows", takes: [
    // drawn at 9.5 counting up from 189; 213 by ~13.5; the lustre crosses the wall ~18
    { args: ["-onboarded", "-sampleData", "-demo", "win"], seconds: 26, cut: "9.5-26" } ] },
  { id: "03", name: "no-streak", takes: [
    // the count runs 69 → 213 from 5.5; the swept bench is drawn at 3.5, and at ~9.5 the
    // system rating prompt (factoryReviewPrompt, tripped by the sample sessions) covers it
    { args: ["-onboarded", "-sampleData", "-screen", "progress"], seconds: 18, cut: "5-15" },
    { args: ["-onboarded", "-sampleData", "-swept"], seconds: 18, cut: "3.5-9.4" } ] },
  { id: "04", name: "bought-once", takes: [
    // onboarding page 1 at 3.5; the bench shows first and the paywall is up by 7.5
    { args: ["-reset"], seconds: 18, cut: "3.5-10" },
    { args: ["-onboarded", "-sampleData", "-fakeProducts", "-screen", "paywall"], seconds: 18, cut: "7.5-17" } ] },
  { id: "05", name: "the-first-tile", takes: [
    // a first-ever tile peeks at ~4 and again ~6.5; the Wall is drawn at 9.5
    { args: ["-onboarded", "-reset"], seconds: 20, cut: "3.2-11" },
    { args: ["-onboarded", "-sampleData", "-screen", "wall"], seconds: 18, cut: "9.5-17.5" } ] },
];

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
const simctl = (...a) => execFileSync("xcrun", ["simctl", ...a], { stdio: "pipe" });

function install() {
  const products = join(app, "ios", ".build", "Build", "Products", "Release-iphonesimulator");
  const built = existsSync(products) && readdirSync(products).find((f) => f.endsWith(".app"));
  if (!built) throw new Error(`no .app in ${products}; run tools/sim.sh build first`);
  try { simctl("uninstall", udid, bundle); } catch {}
  simctl("install", udid, join(products, built));
}

async function take(args, seconds, out) {
  try { simctl("terminate", udid, bundle); } catch {}
  await sleep(800);
  rmSync(out, { force: true });
  const rec = spawn("xcrun", ["simctl", "io", udid, "recordVideo", "--codec=h264", "--force", out],
    { stdio: ["ignore", "pipe", "pipe"] });
  // recordVideo prints "Recording started" once frames are flowing.
  await new Promise((resolve) => {
    const t = setTimeout(resolve, 4000);
    rec.stderr.on("data", (d) => { if (/started/i.test(d)) { clearTimeout(t); resolve(); } });
  });
  simctl("launch", udid, bundle, ...args);
  await sleep(seconds * 1000);
  rec.kill("SIGINT");
  await new Promise((r) => rec.on("exit", r));
  if (!existsSync(out)) throw new Error(`recordVideo wrote nothing to ${out}`);
}

// --raw records the takes and stops there, to measure where each one really starts with
// frames.swift. (Exporting a whole take, from frame 0, fails on a runner with "Cannot Decode";
// every trimmed range exports.)
// --reuse converts the takes already in raw/ without recording again.
const flags = process.argv.slice(2).filter((a) => a.startsWith("--"));
const only = process.argv.slice(2).filter((a) => !a.startsWith("--"));
let installed = false;
for (const clip of CLIPS.filter((c) => !only.length || only.includes(c.id))) {
  const takes = [];
  for (const [i, t] of clip.takes.entries()) {
    const out = join(raw, `${clip.id}-${clip.name}${clip.takes.length > 1 ? `-${i + 1}` : ""}.mov`);
    if (!flags.includes("--reuse") || !existsSync(out)) {
      if (!installed) { install(); installed = true; }
      await take(t.args, t.seconds, out);
    }
    takes.push([t.cut, out]);
  }
  if (flags.includes("--raw")) continue;
  const final = join(clips, `${clip.id}-${clip.name}.mp4`);
  // The runner has no ffmpeg; vertical.swift does the scale, pad, 30 fps and join in AVFoundation.
  process.stdout.write(execFileSync("xcrun", ["swift", join(here, "vertical.swift"), final,
    ...takes.flat()], { stdio: ["ignore", "pipe", "ignore"] }));
}
