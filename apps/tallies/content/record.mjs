#!/usr/bin/env node
/**
 * Record the launch-kit footage for Tallies on the booted simulator.
 *
 *   SIM_UDID=<udid> node apps/tallies/content/record.mjs [shot …]
 *
 * Nothing on a runner can touch the screen, so every shot is a launch flag that makes the app
 * perform it (ios/App/LaunchOptions.swift). Each one starts `simctl io recordVideo`, launches
 * the app through tools/sim.sh, waits out the beat list, and stops the recording with SIGINT —
 * the Ctrl-C the skill asks for — so the .mov is finalised rather than truncated.
 *
 * Writes content/raw/<shot>.mov (gitignored). Build first: tools/sim.sh build apps/tallies/ios Tallies
 */
import { spawn, execFileSync } from "node:child_process";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const here = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(here, "../../..");
const raw = path.join(here, "raw");
fs.mkdirSync(raw, { recursive: true });

const udid = process.env.SIM_UDID;
if (!udid) { console.error("record.mjs: SIM_UDID is not set"); process.exit(1); }

const base = ["-onboarded", "-reset", "-sampleData"];
export const SHOTS = {
  cut:      { secs: 14, args: [...base, "-pro", "-demo", "cut"] },
  score:    { secs: 16, args: [...base, "-pro", "-demo", "score"] },
  bench:    { secs: 8,  args: [...base] },
  ledger:   { secs: 8,  args: [...base, "-pro", "-screen", "ledger"] },
  day5:     { secs: 7,  args: [...base, "-pro", "-days", "5", "-screen", "face"] },
  day500:   { secs: 7,  args: [...base, "-pro", "-days", "500", "-screen", "face"] },
  paywall:  { secs: 7,  args: [...base, "-fakeProducts", "-screen", "paywall"] },
  settings: { secs: 6,  args: [...base, "-screen", "settings"] },
};

const wait = (ms) => new Promise((r) => setTimeout(r, ms));

async function record(name) {
  const shot = SHOTS[name];
  if (!shot) throw new Error(`unknown shot '${name}'; one of ${Object.keys(SHOTS).join(", ")}`);
  const out = path.join(raw, `${name}.mov`);
  const rec = spawn("xcrun", ["simctl", "io", udid, "recordVideo", "--codec=h264", "--force", out], { stdio: "ignore" });
  const done = new Promise((r) => rec.on("exit", r));
  await wait(1500);
  execFileSync(path.join(root, "tools/sim.sh"), ["run", path.join(root, "apps/tallies/ios"), "Tallies", ...shot.args], { stdio: "ignore" });
  await wait(shot.secs * 1000);
  rec.kill("SIGINT");
  await done;
  const kb = fs.existsSync(out) ? (fs.statSync(out).size / 1024).toFixed(0) : 0;
  console.log(`${name}: ${kb} KB → ${path.relative(root, out)}`);
}

const which = process.argv.slice(2);
for (const name of which.length ? which : Object.keys(SHOTS)) await record(name);
