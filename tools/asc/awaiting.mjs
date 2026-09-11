#!/usr/bin/env node
/**
 * Print the slug of every app the owner has just created in App Store Connect and the factory
 * has not uploaded yet: the chain finished (compliance and register ok), app-submit has never
 * run for it, and the app record now exists.
 *
 *   node tools/asc/awaiting.mjs [slug]
 *
 * app-await-record runs this and starts app-submit for each one, which is what makes creating
 * the record the owner's whole go-ahead for TestFlight. An app whose submit ran and failed is
 * not here: that needs a person, not a retry every minute.
 */
import fs from "node:fs";
import { appFacts, findApp } from "./asc.mjs";

const only = process.argv[2];
for (const slug of only ? [only] : fs.readdirSync("apps")) {
  const statePath = `apps/${slug}/state.json`;
  if (!fs.existsSync(statePath) || !fs.existsSync(`apps/${slug}/qa.json`)) continue;
  const stage = (fs.existsSync(`apps/${slug}/STATUS.md`) ? fs.readFileSync(`apps/${slug}/STATUS.md`, "utf8") : "")
    .match(/^stage:\s*(\S+)/m)?.[1] ?? "";
  if (/^(shelved|stopped|archived)/.test(stage)) continue;
  const st = JSON.parse(fs.readFileSync(statePath, "utf8")).stages ?? {};
  if (st.compliance?.status !== "ok" || st.register?.status !== "ok" || st.submit) continue;
  if (await findApp(appFacts(slug).bundleId)) console.log(slug);
}
