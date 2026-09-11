#!/usr/bin/env node
/**
 * Make every build of an app reach the owner's phone through TestFlight, with no setup.
 *
 *   node tools/asc/testflight.mjs <slug>           # dry run
 *   node tools/asc/testflight.mjs <slug> --apply
 *
 * A new app has no TestFlight group at all, so an uploaded build reaches nobody until someone
 * makes one in the browser — Quizday sat on TestFlight like that. This creates an internal
 * group, "Factory", with access to all builds, and puts the owner in it: the App Store
 * Connect users whose email is in TESTFLIGHT_TESTERS (comma-separated), or else the App
 * Review contact, REVIEW_EMAIL. Internal testers must be App Store Connect users, and not
 * every user on the team wants an invite for every app, so nobody else is added.
 * app-submit runs it before the upload, so the build appears in the owner's TestFlight app
 * as soon as Apple finishes processing it. Idempotent.
 */
import { asc, ascAll, findApp, appFacts } from "./asc.mjs";

const [slug, ...flags] = process.argv.slice(2);
const apply = flags.includes("--apply");
if (!slug) {
  console.error("usage: testflight.mjs <slug> [--apply]");
  process.exit(1);
}
const GROUP = "Factory";
const { bundleId } = appFacts(slug);
const app = await findApp(bundleId);
if (!app) {
  console.error(`No app record for ${bundleId}; tools/asc/register.mjs says what to create.`);
  process.exit(1);
}

let group = (await ascAll(`/apps/${app.id}/betaGroups?limit=200`))
  .find((g) => g.attributes.isInternalGroup && g.attributes.name === GROUP);
if (group) {
  console.log(`group    reuse   "${GROUP}" (${group.id})`);
} else if (!apply) {
  console.log(`group    create  "${GROUP}", internal, every build`);
} else {
  group = (await asc("POST", "/betaGroups", {
    data: {
      type: "betaGroups",
      attributes: { name: GROUP, isInternalGroup: true, hasAccessToAllBuilds: true },
      relationships: { app: { data: { type: "apps", id: app.id } } },
    },
  })).data;
  console.log(`group    created "${GROUP}" (${group.id}), internal, every build`);
}

const wanted = (process.env.TESTFLIGHT_TESTERS || process.env.REVIEW_EMAIL || "")
  .split(",").map((e) => e.trim().toLowerCase()).filter(Boolean);
const people = (await ascAll("/users?limit=200"))
  .filter((u) => wanted.includes(u.attributes.username.toLowerCase()));
if (!people.length) {
  // A warning, not a failure: the upload is still worth doing, and the owner can add
  // themselves to the group in the browser.
  console.log(`::warning::No App Store Connect user matches TESTFLIGHT_TESTERS or REVIEW_EMAIL, so nobody was added to "${GROUP}".`);
}
const already = group
  ? new Set((await ascAll(`/betaGroups/${group.id}/betaTesters?limit=200`)).map((t) => t.attributes.email?.toLowerCase()))
  : new Set();

for (const u of people) {
  const email = u.attributes.username;
  const who = `${u.attributes.firstName ?? ""} ${u.attributes.lastName ?? ""}`.trim() || "user";
  if (already.has(email.toLowerCase())) {
    console.log(`tester   reuse   ${who} (${u.attributes.roles.join("+")})`);
  } else if (!apply || !group) {
    console.log(`tester   add     ${who} (${u.attributes.roles.join("+")})`);
  } else {
    await asc("POST", "/betaTesters", {
      data: {
        type: "betaTesters",
        attributes: { email, firstName: u.attributes.firstName, lastName: u.attributes.lastName },
        relationships: { betaGroups: { data: [{ type: "betaGroups", id: group.id }] } },
      },
    });
    console.log(`tester   added   ${who} (${u.attributes.roles.join("+")})`);
  }
}
