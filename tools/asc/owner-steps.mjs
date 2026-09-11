#!/usr/bin/env node
/**
 * The owner's whole part of launching an app, printed from the repository alone: no
 * credentials, no network, so a routine's sandbox can quote it in the "ready" message.
 *
 *   node tools/asc/owner-steps.mjs <slug>
 */
import { appFacts, recordInstructions, privacyInstructions } from "./asc.mjs";

const slug = process.argv[2];
if (!slug) {
  console.error("usage: owner-steps.mjs <slug>");
  process.exit(1);
}
const facts = appFacts(slug);
console.log(`1. Create the app in App Store Connect (skip if it exists), then answer App Privacy:

${recordInstructions(facts).replace(/^/gm, "   ")}

   ${privacyInstructions(slug).replace(/\n/g, "\n   ")}

2. Upload to TestFlight. This also creates the in-app purchases:
   gh workflow run app-submit.yml -f slug=${slug} -f confirm=SUBMIT -R vladmarian20005/appfactory

3. On your phone, from TestFlight: the reminder fires, haptics feel right, the share sheet
   opens, and a sandbox purchase completes.

4. Launch. This sets the age rating, categories, price and availability, attaches the build
   and every purchase, and submits for review:
   gh workflow run app-release.yml -f slug=${slug} -f confirm=SUBMIT -R vladmarian20005/appfactory`);
