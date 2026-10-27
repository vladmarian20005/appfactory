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
import { mkdirSync, readFileSync, rmSync, existsSync } from "node:fs";
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
//
// `-sampleData` only seeds an empty store, so every take that wants it also passes `-reset`:
// without it the chart showed whatever the previous take left behind ("1 evening in a row").
const CLIPS = [
  { id: "01", name: "the-pour", takes: [
    // drawn at 7.9; pours from 9, round and round, the rack refilling at 21
    { args: ["-onboarded", "-reset", "-level", "12", "-demo", "pour"], seconds: 30, cut: "7.9-29" } ] },
  { id: "02", name: "the-charted-line", takes: [
    // the line armed at 5, then four pours down it
    { args: ["-onboarded", "-reset", "-level", "12", "-moves", "4", "-hint"], seconds: 16, cut: "4.8-10.5" },
    // last two pours 6–9, the sun and the count from 13, settled by 16
    { args: ["-onboarded", "-reset", "-level", "12", "-demo", "win"], seconds: 20, cut: "5.8-19" } ] },
  { id: "03", name: "the-same-pool", takes: [
    // drawn at 7.5: nine evenings in a row, today's pool, the month lit
    { args: ["-onboarded", "-reset", "-sampleData", "-screen", "progress"], seconds: 16, cut: "7.6-13" },
    // today's shared board, pouring from 7
    { args: ["-onboarded", "-reset", "-daily", "-demo", "pour"], seconds: 22, cut: "5.8-22" } ] },
  { id: "04", name: "nothing-runs-out", takes: [
    { args: ["-reset"], seconds: 16, cut: "4.8-10" },                                   // onboarding
    { args: ["-onboarded", "-reset", "-sampleData", "-screen", "packs"], seconds: 15, cut: "4.9-9.5" },
    // the board shows first; the paywall is up from 5
    { args: ["-onboarded", "-reset", "-sampleData", "-fakeProducts", "-screen", "paywall"], seconds: 15, cut: "4.9-12" } ] },
  { id: "05", name: "a-shape-on-every-colour", takes: [
    // drawn at 5.5; pours from 9
    { args: ["-onboarded", "-reset", "-pro", "-accessible", "-level", "34", "-demo", "pour"], seconds: 30, cut: "5.6-29" } ] },
];

// FactoryKit asks for a rating on the third session, and a run of takes is many sessions: the
// first clip came back with App Store's sheet over the pour. Answering "already asked for this
// version" through the launch-argument defaults domain keeps the sheet away without touching
// the app; @AppStorage reads that domain like any other.
const version = readFileSync(join(here, "..", "ios", "project.yml"), "utf8")
  .match(/MARKETING_VERSION:\s*"?([\d.]+)/)[1];
for (const c of CLIPS) for (const t of c.takes) t.args.push("-factory.reviewedVersion", version);

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
const simctl = (...a) => execFileSync("xcrun", ["simctl", ...a], { stdio: "pipe" });

async function take(args, seconds, out) {
  try { simctl("terminate", udid, bundle); } catch {}
  await sleep(800);
  rmSync(out, { force: true });
  const rec = spawn("xcrun", ["simctl", "io", udid, "recordVideo", "--codec=h264", "--force", out],
    { stdio: ["ignore", "pipe", "pipe"] });
  // Listen for the exit now: a recorder that dies at once would otherwise exit before anyone
  // waits for it, and the script would hang on an event that already happened.
  const exited = new Promise((r) => rec.on("exit", r));
  // recordVideo prints "Recording started" once frames are flowing.
  await new Promise((resolve) => {
    const t = setTimeout(resolve, 4000);
    rec.stderr.on("data", (d) => { if (/started/i.test(d)) { clearTimeout(t); resolve(); } });
  });
  try {
    simctl("launch", udid, bundle, ...args);
    await sleep(seconds * 1000);
  } finally {
    // Always stop the recorder. One left running after a failed launch holds the device, and
    // every later recordVideo on it silently writes nothing.
    rec.kill("SIGINT");
    await exited;
  }
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
