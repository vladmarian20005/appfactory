#!/usr/bin/env node
/**
 * What happened to the apps after the factory let go of them.
 *
 *   node tools/asc/monitor.mjs [slug] [--days 3] [--json]
 *
 * The factory could take an idea to App Review and then knew nothing: no stage ran after
 * `release`, so a rejection sat unread until someone opened App Store Connect, and the first
 * one-star review about a bug nobody caught would have sat there with it. Every other stage
 * asserts something; this one only looks, and says what needs a person.
 *
 * Three things, per app that has a record:
 *   · the version's review state — REJECTED and its cousins are why this exists
 *   · the newest build and whether TestFlight still has it (a build expires after 90 days)
 *   · customer reviews, with anything at three stars or under from the last `--days` called out
 *
 * Exits 1 when something needs a person, so a scheduled run is a red tick rather than a log
 * nobody reads. Nothing here writes to App Store Connect.
 */
import fs from "node:fs";
import { ascAll, ascMaybe, appFacts, findApp } from "./asc.mjs";

const argv = process.argv.slice(2);
const asJson = argv.includes("--json");
const days = Number(argv[argv.indexOf("--days") + 1]) || 3;
const only = argv.find((a) => !a.startsWith("--") && argv[argv.indexOf(a) - 1] !== "--days");

// The states that mean a person has to do something, and what they mean in plain words.
const NEEDS_A_PERSON = {
  REJECTED: "App Review rejected it. Read the resolution centre, fix the app, submit again.",
  METADATA_REJECTED: "App Review rejected the metadata, not the binary. Fix the listing and submit again.",
  DEVELOPER_REJECTED: "Somebody withdrew this version. It will not ship until it is submitted again.",
  INVALID_BINARY: "The uploaded binary is invalid. Upload a new build.",
};
// States that are simply in motion; saying so is what stops someone checking by hand.
const IN_FLIGHT = ["WAITING_FOR_REVIEW", "IN_REVIEW", "PENDING_DEVELOPER_RELEASE", "PROCESSING_FOR_APP_STORE"];

const since = Date.now() - days * 86_400_000;
const report = [];
let needsAction = 0;

const slugs = only ? [only] : fs.readdirSync("apps").filter((s) => fs.existsSync(`apps/${s}/state.json`));

for (const slug of slugs) {
  // An app mid-build has a state.json and no qa.json yet, so there is no bundle id to look
  // up. Check before asking: appFacts exits the process rather than throwing, which would end
  // the whole sweep on the first unbuilt app — and a monitor that stops at the first gap is
  // the kind of monitor that is quietly not running.
  if (!fs.existsSync(`apps/${slug}/qa.json`)) {
    report.push({ slug, record: false, notes: ["not built yet (no qa.json), so nothing to watch"] });
    continue;
  }
  const facts = appFacts(slug);

  const app = await findApp(facts.bundleId);
  if (!app) {
    report.push({ slug, record: false, notes: ["no App Store Connect record yet"] });
    continue;
  }

  const [versions, builds, reviews] = await Promise.all([
    ascAll(`/apps/${app.id}/appStoreVersions?limit=3&fields[appStoreVersions]=versionString,appStoreState,createdDate`),
    ascAll(`/builds?filter[app]=${app.id}&limit=3&sort=-uploadedDate&fields[builds]=version,processingState,uploadedDate,expired`),
    // A brand new app has no reviews and Apple answers 404 rather than an empty list.
    ascMaybe(`/apps/${app.id}/customerReviews?limit=50&sort=-createdDate&fields[customerReviews]=rating,title,body,createdDate,territory`)
      .then((r) => r?.data ?? [])
      .catch(() => []),
  ]);

  const notes = [];
  const version = versions[0];
  if (version) {
    const state = version.attributes.appStoreState;
    if (NEEDS_A_PERSON[state]) {
      notes.push(`ACTION ${version.attributes.versionString}: ${NEEDS_A_PERSON[state]}`);
      needsAction++;
    } else if (IN_FLIGHT.includes(state)) {
      notes.push(`${version.attributes.versionString} is ${state}; nothing to do but wait.`);
    }
  }

  const build = builds[0];
  if (build?.attributes.expired) {
    notes.push(`ACTION the newest build ${build.attributes.version} has expired on TestFlight; upload another.`);
    needsAction++;
  }
  if (build?.attributes.processingState === "FAILED") {
    notes.push(`ACTION build ${build.attributes.version} failed processing; it will never be installable.`);
    needsAction++;
  }

  const rated = reviews.filter((r) => typeof r.attributes.rating === "number");
  const average = rated.length ? rated.reduce((n, r) => n + r.attributes.rating, 0) / rated.length : null;
  const fresh = reviews.filter((r) => Date.parse(r.attributes.createdDate) >= since);
  const unhappy = fresh.filter((r) => r.attributes.rating <= 3);
  if (unhappy.length) {
    notes.push(`ACTION ${unhappy.length} review(s) at three stars or under in the last ${days} day(s).`);
    needsAction++;
  }

  report.push({
    slug,
    record: true,
    name: app.attributes.name,
    version: version ? { string: version.attributes.versionString, state: version.attributes.appStoreState } : null,
    build: build
      ? { version: build.attributes.version, state: build.attributes.processingState, expired: build.attributes.expired }
      : null,
    reviews: { total: reviews.length, average, fresh: fresh.length },
    unhappy: unhappy.map((r) => ({
      rating: r.attributes.rating,
      title: r.attributes.title,
      body: (r.attributes.body ?? "").slice(0, 400),
      territory: r.attributes.territory,
      at: r.attributes.createdDate,
    })),
    notes,
  });
}

if (asJson) {
  console.log(JSON.stringify({ at: new Date().toISOString(), days, needsAction, apps: report }, null, 2));
} else {
  for (const a of report) {
    if (!a.record) {
      console.log(`${a.slug}: ${a.notes[0]}`);
      continue;
    }
    const stars = a.reviews.average === null ? "no ratings" : `${a.reviews.average.toFixed(2)}★ over ${a.reviews.total}`;
    console.log(`\n${a.slug} — ${a.name}`);
    console.log(`  version  ${a.version ? `${a.version.string} ${a.version.state}` : "none"}`);
    console.log(`  build    ${a.build ? `${a.build.version} ${a.build.state}${a.build.expired ? " EXPIRED" : ""}` : "none"}`);
    console.log(`  reviews  ${stars}`);
    for (const n of a.notes) console.log(`  ${n}`);
    for (const r of a.unhappy) {
      console.log(`    ${r.rating}★ ${r.territory} ${r.at.slice(0, 10)} — ${r.title}`);
      if (r.body) console.log(`      ${r.body.replace(/\s+/g, " ")}`);
    }
  }
  console.log(needsAction ? `\n${needsAction} thing(s) need a person.` : "\nNothing needs a person.");
}

process.exit(needsAction ? 1 : 0);
