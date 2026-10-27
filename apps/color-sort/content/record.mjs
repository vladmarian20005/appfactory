// Records the five launch clips on the booted simulator.
//
//   node apps/color-sort/content/record.mjs [01 02 …] [--raw] [--reuse]
//
// Quizday's recorder, with Tidepour's takes. Needs `tools/sim.sh build apps/color-sort/ios
// Tidepour` first, and SIM_UDID (or a booted device). Nothing on a runner can touch the
// screen, so every take is a launch flag from LaunchOptions.swift: `-demo pour` makes the app
// pour down its own charted line and refill, `-demo win` plays the last two pours into the
// win, the rest open a screen. Each take is recorded raw to content/raw/NN-*.mov, stopped with
// SIGINT as recordVideo expects, and converted to a vertical 1080x1920 30 fps MP4 in
// content/clips/ by vertical.swift.
import { execFileSync, spawn } from "node:child_process";
import { mkdirSync, rmSync, existsSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const here = dirname(fileURLToPath(import.meta.url));
const raw = join(here, "raw");
const clips = join(here, "clips");
mkdirSync(raw, { recursive: true });
mkdirSync(clips, { recursive: true });

const bundle = "com.starhiveconcept.colorsort";
const booted = () => Object.values(JSON.parse(execFileSync("xcrun",
  ["simctl", "list", "devices", "booted", "-j"]).toString()).devices).flat()[0]?.udid;
const udid = process.env.SIM_UDID || booted();
if (!udid) throw new Error("no booted simulator and no SIM_UDID");

// A take is one launch and one recording; a clip is one or more takes, joined. `cut` is the
// part of the raw take kept, "start-end" in seconds, so every clip starts where the app has
// drawn rather than on the home screen. Measured from contact sheets of the raw takes
// (frames.swift), not guessed.
const CLIPS = [
  { id: "01", name: "the-pour", takes: [
    { args: ["-onboarded", "-reset", "-level", "12", "-demo", "pour"], seconds: 30, cut: "CUT" } ] },
  { id: "02", name: "the-charted-line", takes: [
    { args: ["-onboarded", "-reset", "-level", "12", "-moves", "4", "-hint"], seconds: 16, cut: "CUT" },
    { args: ["-onboarded", "-reset", "-level", "12", "-demo", "win"], seconds: 20, cut: "CUT" } ] },
  { id: "03", name: "the-same-pool", takes: [
    { args: ["-onboarded", "-sampleData", "-screen", "progress"], seconds: 16, cut: "CUT" },
    { args: ["-onboarded", "-reset", "-daily", "-demo", "pour"], seconds: 22, cut: "CUT" } ] },
  { id: "04", name: "nothing-runs-out", takes: [
    { args: ["-reset"], seconds: 16, cut: "CUT" },
    { args: ["-onboarded", "-sampleData", "-screen", "packs"], seconds: 15, cut: "CUT" },
    { args: ["-onboarded", "-sampleData", "-fakeProducts", "-screen", "paywall"], seconds: 15, cut: "CUT" } ] },
  { id: "05", name: "a-shape-on-every-colour", takes: [
    { args: ["-onboarded", "-reset", "-pro", "-accessible", "-level", "34", "-demo", "pour"], seconds: 30, cut: "CUT" } ] },
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
  if (flags.includes("--raw")) continue;
  const final = join(clips, `${clip.id}-${clip.name}.mp4`);
  process.stdout.write(execFileSync("xcrun", ["swift", join(here, "vertical.swift"), final,
    ...takes.flat()], { stdio: ["ignore", "pipe", "inherit"] }));
}
