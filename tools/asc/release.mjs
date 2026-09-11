#!/usr/bin/env node
/**
 * Everything between "the build is on TestFlight" and "Waiting for Review" that App Store
 * Connect's API allows, so launching an app is one workflow run.
 *
 *   node tools/asc/release.mjs <slug>           # dry run: what the release still lacks
 *   node tools/asc/release.mjs <slug> --apply   # set it, and submit the version with its purchases
 *
 * app-release runs deliver first (listing text, screenshots, review contact), then this with
 * --apply. In order, each step only if it is not already so:
 *   content rights, categories and the age rating questionnaire, from store/release.json;
 *   the price (free) and availability in every territory;
 *   the latest processed build attached to the editable version, released after approval;
 *   one review submission holding the version AND every in-app purchase and subscription that
 *   is ready: an app's first purchases can only be reviewed with a version, and deliver
 *   refuses a submission holding items it did not add, so it cannot do this part.
 * Nothing is submitted if a purchase fails to attach: a version that goes to review without
 * its purchases ships a paywall that cannot sell anything.
 *
 * App Privacy is the one release requirement the public API cannot touch (no data-usage
 * endpoints exist); it is set once in the browser, alongside creating the app record.
 */
import fs from "node:fs";
import { asc, ascAll, ascMaybe, appFacts, findApp, recordInstructions, privacyInstructions } from "./asc.mjs";
import { loadProducts } from "./products.mjs";

const [slug, ...flags] = process.argv.slice(2);
const apply = flags.includes("--apply");
if (!slug) {
  console.error("usage: release.mjs <slug> [--apply]");
  process.exit(1);
}

const facts = appFacts(slug);
const relPath = `apps/${slug}/store/release.json`;
if (!fs.existsSync(relPath)) {
  console.error(`${relPath} is missing: it names the categories, the content rights and any age rating answer that is not "none".`);
  process.exit(1);
}
const rel = JSON.parse(fs.readFileSync(relPath, "utf8"));
const products = loadProducts(slug);

console.log(apply ? "APPLYING to App Store Connect\n" : "DRY RUN — nothing will be changed (pass --apply)\n");
const done = (what) => console.log(`  ok      ${what}`);
const plan = (what) => console.log(`  ${apply ? "set " : "would"}    ${what}`);
const blockers = [];

const app = await findApp(facts.bundleId);
if (!app) {
  console.error(`No app record for ${facts.bundleId}. Create it, then run this again:\n\n${recordInstructions(facts)}\n\n${privacyInstructions(slug)}`);
  process.exit(1);
}
console.log(`app  ${app.attributes.name}  id ${app.id}\n`);

// ── the editable version ──────────────────────────────────────────────────────
const EDITABLE = ["PREPARE_FOR_SUBMISSION", "DEVELOPER_REJECTED", "REJECTED", "METADATA_REJECTED", "INVALID_BINARY"];
const versions = await ascAll(`/apps/${app.id}/appStoreVersions?filter[platform]=IOS&limit=20`);
const inReview = versions.find((v) => ["WAITING_FOR_REVIEW", "IN_REVIEW"].includes(v.attributes.appVersionState));
if (inReview) {
  console.log(`version ${inReview.attributes.versionString} is already ${inReview.attributes.appVersionState}; nothing to do.`);
  process.exit(0);
}
const version = versions.find((v) => EDITABLE.includes(v.attributes.appVersionState));
if (!version) {
  console.error(`No editable iOS version (states: ${versions.map((v) => `${v.attributes.versionString} ${v.attributes.appVersionState}`).join(", ")}).`);
  process.exit(1);
}
console.log(`version ${version.attributes.versionString}  ${version.attributes.appVersionState}`);

// ── content rights ────────────────────────────────────────────────────────────
{
  const want = rel.contentRights ?? "DOES_NOT_USE_THIRD_PARTY_CONTENT";
  if (app.attributes.contentRightsDeclaration === want) done(`content rights ${want}`);
  else {
    plan(`content rights ${want}`);
    if (apply) await asc("PATCH", `/apps/${app.id}`, { data: { type: "apps", id: app.id, attributes: { contentRightsDeclaration: want } } });
  }
}

// ── categories and age rating, on the editable app info ───────────────────────
const infos = await ascAll(`/apps/${app.id}/appInfos?limit=10`);
const info = infos.find((i) => !["READY_FOR_DISTRIBUTION", "REPLACED_WITH_NEW_INFO"].includes(i.attributes.state)) ?? infos[0];
{
  const slots = ["primaryCategory", "primarySubcategoryOne", "primarySubcategoryTwo", "secondaryCategory", "secondarySubcategoryOne", "secondarySubcategoryTwo"];
  const want = Object.fromEntries(slots.filter((s) => rel[s]).map((s) => [s, rel[s]]));
  if (!want.primaryCategory) blockers.push(`${relPath} has no primaryCategory`);
  const have = {};
  for (const s of Object.keys(want)) have[s] = (await ascMaybe(`/appInfos/${info.id}/${s}`))?.id ?? null;
  const diff = Object.keys(want).filter((s) => have[s] !== want[s]);
  if (!diff.length) done(`categories ${Object.values(want).join(", ")}`);
  else {
    plan(`categories ${diff.map((s) => `${s}=${want[s]}`).join(", ")}`);
    if (apply) {
      await asc("PATCH", `/appInfos/${info.id}`, {
        data: {
          type: "appInfos",
          id: info.id,
          relationships: Object.fromEntries(diff.map((s) => [s, { data: { type: "appCategories", id: want[s] } }])),
        },
      });
    }
  }
}
{
  // Every question answered "none" unless release.json says otherwise. The factory builds
  // calm, single-player apps with no web views, chat or user content; an app that has any of
  // that declares it in release.json, and the compliance gate is where that gets noticed.
  const age = await ascMaybe(`/appInfos/${info.id}/ageRatingDeclaration`);
  const NOT_QUESTIONS = new Set(["kidsAgeBand", "ageRatingOverride", "ageRatingOverrideV2", "koreaAgeRatingOverride", "developerAgeRatingInfoUrl"]);
  const want = {};
  for (const [k, v] of Object.entries(age.attributes)) {
    if (NOT_QUESTIONS.has(k)) continue;
    const isBool = typeof v === "boolean" || ["advertising", "gambling", "healthOrWellnessTopics", "lootBox", "messagingAndChat", "parentalControls", "ageAssurance", "socialMedia", "socialMediaAgeRestricted", "unrestrictedWebAccess", "userGeneratedContent"].includes(k);
    want[k] = rel.ageRating?.[k] ?? (isBool ? false : "NONE");
  }
  const diff = Object.keys(want).filter((k) => age.attributes[k] !== want[k]);
  if (!diff.length) done(`age rating, all ${Object.keys(want).length} questions answered`);
  else {
    plan(`age rating: ${diff.length} of ${Object.keys(want).length} answers`);
    if (apply) {
      await asc("PATCH", `/ageRatingDeclarations/${age.id}`, {
        data: { type: "ageRatingDeclarations", id: age.id, attributes: Object.fromEntries(diff.map((k) => [k, want[k]])) },
      });
    }
  }
}

// ── price and availability ────────────────────────────────────────────────────
{
  const schedule = await ascMaybe(`/apps/${app.id}/appPriceSchedule`);
  const manual = schedule ? await ascAll(`/appPriceSchedules/${schedule.id}/manualPrices?limit=5`).catch(() => []) : [];
  const want = String(rel.price ?? "0");
  if (manual.length) done("price schedule");
  else {
    const points = await ascAll(`/apps/${app.id}/appPricePoints?filter[territory]=USA&limit=200`);
    const point = points.find((p) => Number(p.attributes.customerPrice) === Number(want));
    if (!point) blockers.push(`no USA app price point at ${want}`);
    else {
      plan(`price ${Number(want) === 0 ? "Free" : `${want} USD`}, the rest equalized by Apple`);
      if (apply) {
        await asc("POST", "/appPriceSchedules", {
          data: {
            type: "appPriceSchedules",
            relationships: {
              app: { data: { type: "apps", id: app.id } },
              baseTerritory: { data: { type: "territories", id: "USA" } },
              manualPrices: { data: [{ type: "appPrices", id: "${price}" }] },
            },
          },
          included: [{
            type: "appPrices",
            id: "${price}",
            attributes: { startDate: null },
            relationships: { appPricePoint: { data: { type: "appPricePoints", id: point.id } } },
          }],
        });
      }
    }
  }
}
{
  const have = await ascMaybe(`/apps/${app.id}/appAvailabilityV2`);
  if (have) done("availability");
  else {
    const territories = await ascAll("/territories?limit=200");
    plan(`availability in all ${territories.length} territories`);
    if (apply) {
      await asc("POST", "/v2/appAvailabilities", {
        data: {
          type: "appAvailabilities",
          attributes: { availableInNewTerritories: true },
          relationships: {
            app: { data: { type: "apps", id: app.id } },
            territoryAvailabilities: { data: territories.map((t) => ({ type: "territoryAvailabilities", id: `\${${t.id}}` })) },
          },
        },
        included: territories.map((t) => ({
          type: "territoryAvailabilities",
          id: `\${${t.id}}`,
          attributes: { available: true },
          relationships: { territory: { data: { type: "territories", id: t.id } } },
        })),
      });
    }
  }
}

// ── the build ─────────────────────────────────────────────────────────────────
{
  const attached = await ascMaybe(`/appStoreVersions/${version.id}/build`);
  if (attached) done(`build ${attached.attributes.version} attached`);
  else {
    const builds = await asc("GET",
      `/builds?filter[app]=${app.id}&filter[processingState]=VALID&filter[expired]=false` +
      `&filter[preReleaseVersion.version]=${encodeURIComponent(version.attributes.versionString)}&sort=-uploadedDate&limit=1`);
    const build = builds.data?.[0];
    if (!build) blockers.push(`no processed build for ${version.attributes.versionString}; run app-submit and wait for Apple to finish processing`);
    else {
      plan(`build ${build.attributes.version} attached to ${version.attributes.versionString}`);
      if (apply) {
        await asc("PATCH", `/appStoreVersions/${version.id}/relationships/build`, { data: { type: "builds", id: build.id } });
      }
    }
  }
  if (version.attributes.releaseType !== "AFTER_APPROVAL") {
    plan("release automatically after approval");
    if (apply) {
      await asc("PATCH", `/appStoreVersions/${version.id}`, {
        data: { type: "appStoreVersions", id: version.id, attributes: { releaseType: "AFTER_APPROVAL" } },
      });
    }
  }
}

// ── the purchases that go to review with it ───────────────────────────────────
const REVIEWABLE = ["PREPARE_FOR_SUBMISSION", "READY_FOR_REVIEW"];
const items = []; // { rel, type, id, label, required }
{
  const pick = (vs) => vs.find((v) => REVIEWABLE.includes(v.attributes.state));
  const known = new Set(); // every product App Store Connect has, in any state
  for (const iap of await ascAll(`/apps/${app.id}/inAppPurchasesV2?limit=200`)) {
    const { productId, state } = iap.attributes;
    known.add(productId);
    if (state === "MISSING_METADATA") { blockers.push(`${productId} is Missing Metadata; app-submit runs iap.mjs, re-run it`); continue; }
    if (state !== "READY_TO_SUBMIT") continue; // approved, or already with Apple
    const v = pick(await ascAll(`/v2/inAppPurchases/${iap.id}/versions?limit=20`));
    if (v) items.push({ rel: "inAppPurchaseVersion", type: "inAppPurchaseVersions", id: v.id, label: productId, required: true });
    else blockers.push(`${productId} has no version ready for review`);
  }
  for (const g of await ascAll(`/apps/${app.id}/subscriptionGroups?limit=50`)) {
    const gv = pick(await ascAll(`/subscriptionGroups/${g.id}/versions?limit=20`).catch(() => []));
    if (gv) items.push({ rel: "subscriptionGroupVersion", type: "subscriptionGroupVersions", id: gv.id, label: `group ${g.attributes.referenceName}`, required: false });
    for (const s of await ascAll(`/subscriptionGroups/${g.id}/subscriptions?limit=50`)) {
      const { productId, state } = s.attributes;
      known.add(productId);
      if (state === "MISSING_METADATA") { blockers.push(`${productId} is Missing Metadata; app-submit runs iap.mjs, re-run it`); continue; }
      if (state !== "READY_TO_SUBMIT") continue;
      const v = pick(await ascAll(`/subscriptions/${s.id}/versions?limit=20`));
      if (v) items.push({ rel: "subscriptionVersion", type: "subscriptionVersions", id: v.id, label: productId, required: true });
      else blockers.push(`${productId} has no version ready for review`);
    }
  }
  // Every product the paywall asks for must exist, or the live app offers nothing to buy.
  // iap.mjs creates them in app-submit.
  for (const p of [...products.subscriptions, ...products.oneTime]) {
    if (!known.has(p.productId)) blockers.push(`${p.productId} is not in App Store Connect; re-run app-submit, which creates it`);
  }
  for (const i of items) console.log(`  review  ${i.label}`);
}

if (blockers.length) {
  console.error("\nCannot submit yet:");
  for (const b of blockers) console.error(`  · ${b}`);
  process.exit(1);
}
if (!apply) {
  console.log(`\nDry run complete. With --apply: one review submission, the version plus ${items.length} purchase item(s), submitted.`);
  process.exit(0);
}

// ── one review submission, then submit ────────────────────────────────────────
const open = await ascAll(`/reviewSubmissions?filter[app]=${app.id}&filter[platform]=IOS&filter[state]=READY_FOR_REVIEW,UNRESOLVED_ISSUES&limit=5`);
let submission = open[0];
if (submission) console.log(`\nreview submission  reuse ${submission.id} (${submission.attributes.state})`);
else {
  submission = (await asc("POST", "/reviewSubmissions", {
    data: { type: "reviewSubmissions", attributes: { platform: "IOS" }, relationships: { app: { data: { type: "apps", id: app.id } } } },
  })).data;
  console.log(`\nreview submission  created ${submission.id}`);
}

// What is already in it, so a re-run adds only what is missing.
const present = new Set();
for (const it of await ascAll(`/reviewSubmissions/${submission.id}/items?limit=100`)) {
  for (const [k, v] of Object.entries(it.relationships ?? {})) if (v?.data?.id) present.add(`${k}:${v.data.id}`);
}
const add = async (relName, type, id) => {
  if (present.has(`${relName}:${id}`)) return "already in it";
  await asc("POST", "/reviewSubmissionItems", {
    data: {
      type: "reviewSubmissionItems",
      relationships: {
        reviewSubmission: { data: { type: "reviewSubmissions", id: submission.id } },
        [relName]: { data: { type, id } },
      },
    },
  });
  return "added";
};

console.log(`  version ${version.attributes.versionString}: ${await add("appStoreVersion", "appStoreVersions", version.id)}`);
for (const i of items) {
  try {
    console.log(`  ${i.label}: ${await add(i.rel, i.type, i.id)}`);
  } catch (e) {
    if (i.required) {
      console.error(`\n${i.label} could not join the review, so nothing was submitted:\n  ${e.message}`);
      process.exit(1);
    }
    console.log(`  ${i.label}: not added (${e.message.split("  ").pop()})`);
  }
}

try {
  const after = (await asc("PATCH", `/reviewSubmissions/${submission.id}`, {
    data: { type: "reviewSubmissions", id: submission.id, attributes: { submitted: true } },
  })).data;
  console.log(`\nSubmitted: ${after.attributes.state}.`);
} catch (e) {
  console.error(`\nApple refused the submission:\n  ${e.message}`);
  if (/privacy/i.test(e.message)) console.error(`\n${privacyInstructions(slug)}`);
  process.exit(1);
}
