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
console.log(`1. Create the app in App Store Connect, then answer App Privacy. The bundle id is already
   in the form's dropdown.

${recordInstructions(facts).replace(/^/gm, "   ")}

   ${privacyInstructions(slug).replace(/\n/g, "\n   ")}

   That is the go-ahead. Within about fifteen minutes the factory notices the record, creates
   the in-app purchases, adds you as a TestFlight tester and uploads the build.

2. Test it from the TestFlight app on your phone, once Apple has processed the build: the
   reminder fires, haptics feel right, the share sheet opens, a sandbox purchase completes.

3. Launch. This sets the age rating, categories, price and availability, attaches the build
   and every purchase, and submits for review:
   gh workflow run app-release.yml -f slug=${slug} -f confirm=SUBMIT -R vladmarian20005/appfactory
   (or GitHub → Actions → app-release → Run workflow)`);
