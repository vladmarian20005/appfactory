// Records the five launch clips on the booted simulator.
//
//   node apps/quizday/content/record.mjs [01 02 …]
//
// Needs `tools/sim.sh build apps/quizday/ios Quizday` first, and SIM_UDID (or the booted
// factory device). Nothing on a runner can touch the screen, so every clip is a launch flag:
// `-demo answer|win` makes the app perform its own press, the rest open a screen. Each take
// is recorded raw to content/raw/NN-*.mov, stopped with SIGINT as recordVideo expects, and
// converted to a vertical 1080x1920 30 fps MP4 in content/clips/. The phone's 1320x2868 is
// scaled to the full 1920 height and padded with the app's newsprint, so nothing is cropped
// and captions can sit in the margins later.
import { execFileSync, spawn } from "node:child_process";
import { mkdirSync, rmSync, writeFileSync, existsSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const here = dirname(fileURLToPath(import.meta.url));
const app = join(here, "..");
const raw = join(here, "raw");
const clips = join(here, "clips");
mkdirSync(raw, { recursive: true });
mkdirSync(clips, { recursive: true });

const bundle = "com.starhiveconcept.quizday";
const booted = () => Object.values(JSON.parse(execFileSync("xcrun",
  ["simctl", "list", "devices", "booted", "-j"]).toString()).devices).flat()[0]?.udid;
const udid = process.env.SIM_UDID || booted();
if (!udid) throw new Error("no booted simulator and no SIM_UDID");

// A take is one launch and one recording. A clip is one or more takes, joined. `cut` is the
// part of the raw take kept, "start-end" in seconds: a cold launch on a runner shows the home
// screen and then a blank window for 3 to 7 s, so every cut starts where the app has drawn.
// The cuts were measured from contact sheets of the raw takes (frames.swift), not guessed.
const CLIPS = [
  { id: "01", name: "the-ink-press", takes: [
    // drawn at 7.0; Q4 pressed right at ~12.6; page turns ~15.5; Q5 pressed wrong ~17.8
    { args: ["-onboarded", "-reset", "-demo", "answer"], seconds: 26, cut: "6.8-26" } ] },
  { id: "02", name: "the-edition-prints", takes: [
    // drawn at 6.0 on question ten; pressed ~12.8; to press ~19.5; settled ~23
    { args: ["-onboarded", "-editions", "19", "-demo", "win"], seconds: 30, cut: "10-31" } ] },
  { id: "03", name: "the-paper", takes: [
    { args: ["-reset"], seconds: 17, cut: "3-11" },                       // onboarding, the press turning
    { args: ["-onboarded", "-reset"], seconds: 19, cut: "4-11" },         // today, unplayed
    { args: ["-onboarded", "-sampleData", "-fakeProducts", "-screen", "paywall"], seconds: 16, cut: "5-11" } ] },
  { id: "04", name: "the-late-edition", takes: [
    { args: ["-onboarded", "-editions", "12", "-screen", "late"], seconds: 17, cut: "4-12" },
    { args: ["-onboarded", "-editions", "12", "-screen", "late", "-lateStart"], seconds: 20, cut: "4-9" },
    { args: ["-onboarded", "-editions", "19", "-answered", "8"], seconds: 17, cut: "5.5-13" } ] },
  { id: "05", name: "the-file", takes: [
    { args: ["-onboarded", "-sampleData", "-screen", "scorecard"], seconds: 19, cut: "5-14" },
    // `-screen share` drew nothing in 17 s on the runner, so the shared front page is shown
    // as the result screen it comes from instead.
    { args: ["-onboarded", "-editions", "19", "-answered", "8"], seconds: 17, cut: "4.8-15" } ] },
];

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
const simctl = (...a) => execFileSync("xcrun", ["simctl", ...a], { stdio: "pipe" });

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

// --raw keeps every frame (trim 0), to measure where each take really starts.
// --reuse converts the takes already in raw/ without recording again.
const flags = process.argv.slice(2).filter((a) => a.startsWith("--"));
const only = process.argv.slice(2).filter((a) => !a.startsWith("--"));
for (const clip of CLIPS.filter((c) => !only.length || only.includes(c.id))) {
  const takes = [];
  for (const [i, t] of clip.takes.entries()) {
    const out = join(raw, `${clip.id}-${clip.name}${clip.takes.length > 1 ? `-${i + 1}` : ""}.mov`);
    if (!flags.includes("--reuse") || !existsSync(out)) await take(t.args, t.seconds, out);
    takes.push([flags.includes("--raw") ? "0" : t.cut, out]);
  }
  const final = join(clips, `${clip.id}-${clip.name}.mp4`);
  // The runner has no ffmpeg; vertical.swift does the scale, pad, 30 fps and join in AVFoundation.
  process.stdout.write(execFileSync("xcrun", ["swift", join(here, "vertical.swift"), final,
    ...takes.flat()], { stdio: ["ignore", "pipe", "ignore"] }));
}
