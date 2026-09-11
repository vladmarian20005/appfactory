#!/usr/bin/env node
/**
 * Get an app as far into App Store Connect as the API allows, and say exactly what is left.
 *
 *   node tools/asc/register.mjs <slug>                 # register the bundle id; report on the app record
 *   node tools/asc/register.mjs <slug> --require-app   # the same, and exit 1 if the record is missing
 *
 * app-register runs the first form when the chain finishes, so the bundle id is already in
 * the New App form's dropdown when the owner gets "ready to submit". app-submit runs the
 * second before it archives anything, so a missing record fails in seconds.
 *
 * The bundle id's name has to be letters, digits and spaces: the portal rejects punctuation.
 */
import fs from "node:fs";
import { asc, ascAll, appFacts, findApp, recordInstructions, privacyInstructions } from "./asc.mjs";

const [slug, ...flags] = process.argv.slice(2);
if (!slug) {
  console.error("usage: register.mjs <slug> [--require-app]");
  process.exit(1);
}
const requireApp = flags.includes("--require-app");
const facts = appFacts(slug);
if (!facts.name) {
  console.error(`apps/${slug}/store/metadata/en-US/name.txt is missing; the build writes the English listing first.`);
  process.exit(1);
}

const summary = [];
const say = (line = "") => {
  console.log(line);
  summary.push(line);
};

// ── bundle id ─────────────────────────────────────────────────────────────────
const ids = await ascAll(`/bundleIds?filter[identifier]=${encodeURIComponent(facts.bundleId)}&limit=200`);
let bundle = ids.find((b) => b.attributes.identifier === facts.bundleId);
if (bundle) {
  say(`Bundle id ${facts.bundleId} is registered (${bundle.id}).`);
} else {
  bundle = (await asc("POST", "/bundleIds", {
    data: {
      type: "bundleIds",
      attributes: {
        name: facts.name.replace(/[^A-Za-z0-9 ]/g, " ").replace(/\s+/g, " ").trim(),
        identifier: facts.bundleId,
        platform: "IOS",
        ...(process.env.TEAM_ID ? { seedId: process.env.TEAM_ID } : {}),
      },
    },
  })).data;
  say(`Bundle id ${facts.bundleId} registered just now (${bundle.id}).`);
}

// ── app record ────────────────────────────────────────────────────────────────
const app = await findApp(facts.bundleId);
if (app) {
  say(`App record exists: ${app.attributes.name} (${app.id}).`);
} else {
  say("");
  say("The app record does not exist yet, and Apple's API cannot create one (POST /v1/apps is");
  say("rejected: 'apps' does not allow CREATE). One visit to App Store Connect, two forms:");
  say("");
  say(recordInstructions(facts));
  say("");
  say(privacyInstructions(slug));
}

if (process.env.GITHUB_STEP_SUMMARY) {
  fs.appendFileSync(process.env.GITHUB_STEP_SUMMARY, `## App Store Connect: \`${slug}\`\n\n\`\`\`\n${summary.join("\n")}\n\`\`\`\n`);
}
if (!app && requireApp) process.exit(1);
