#!/usr/bin/env node
/**
 * What an app sells, read from the files that already describe it, and checked against App
 * Store Connect's limits before anything talks to Apple.
 *
 *   node tools/asc/products.mjs <slug>    # print the products; exit 1 on anything Apple would reject
 *
 * The source is ios/App/Products.storekit. The new-app skill writes it to match the app's
 * product ids exactly, and it is what the paywall is tested against, so creating the App
 * Store Connect products from it keeps the two from drifting. apps/<slug>/iap.json, where one
 * exists, wins: Quizday's was written by hand before this read StoreKit.
 *
 * No credentials and no network, so app-compliance runs it on every app heading for the store.
 * A limit found there costs a fix; found by iap.mjs inside app-submit, it costs a failed upload.
 */
import fs from "node:fs";
import path from "node:path";
import { pathToFileURL } from "node:url";

// ISO 8601 durations in a .storekit file → App Store Connect's enums.
const PERIOD = { P1W: "ONE_WEEK", P1M: "ONE_MONTH", P2M: "TWO_MONTHS", P3M: "THREE_MONTHS", P6M: "SIX_MONTHS", P1Y: "ONE_YEAR" };
const OFFER_DURATION = { P3D: "THREE_DAYS", ...PERIOD, P2W: "TWO_WEEKS" };

// Apple's limits, from the App Store Connect reference ("In-App Purchase information" and
// "Auto-renewable subscription information"). Subscriptions allow a longer description.
const LIMITS = {
  referenceName: 64,
  productId: 100,
  oneTime: { displayName: 30, description: 45 },
  subscription: { displayName: 30, description: 55 },
  groupDisplayName: 30,
};

const readJSON = (p) => JSON.parse(fs.readFileSync(p, "utf8"));
const english = (locs = []) => locs.find((l) => /^en[_-]US$/.test(l.locale)) ?? locs[0] ?? {};

/** The composed screenshot of the paywall: App Review wants to see where the purchase lives. */
function paywallScreenshot(slug) {
  const spec = `apps/${slug}/store/screenshots.json`;
  const dir = `apps/${slug}/store/screenshots/en-US`;
  if (!fs.existsSync(spec) || !fs.existsSync(dir)) return null;
  const shots = readJSON(spec).shots ?? [];
  // compose.mjs names its output 01.png, 02.png… in the order of `shots`.
  let i = shots.findIndex((s) => /paywall/i.test(s.src ?? ""));
  if (i < 0) i = shots.length - 1;
  const file = path.join(dir, `${String(i + 1).padStart(2, "0")}.png`);
  return fs.existsSync(file) ? file : null;
}

export function loadProducts(slug) {
  const problems = [];
  const qaPath = `apps/${slug}/qa.json`;
  const bundleId = fs.existsSync(qaPath) ? readJSON(qaPath).bundleId : null;
  if (!bundleId) problems.push(`${qaPath} has no bundleId`);
  const nameFile = `apps/${slug}/store/metadata/en-US/name.txt`;
  const appName = fs.existsSync(nameFile) ? fs.readFileSync(nameFile, "utf8").trim() : null;
  const privacyPath = `apps/${slug}/privacy.json`;
  const freeTier = fs.existsSync(privacyPath) ? readJSON(privacyPath).purchases?.freeTier : null;
  const reviewNote = (displayName) =>
    [`${displayName} is bought on the paywall; a sandbox account completes the purchase.`,
     freeTier ? `Free without it: ${freeTier}` : null].filter(Boolean).join(" ");

  const out = {
    slug, bundleId, appName, baseTerritory: "USA",
    group: null, subscriptions: [], oneTime: [],
    reviewScreenshot: paywallScreenshot(slug), source: null, problems,
  };

  const iapJson = `apps/${slug}/iap.json`;
  const storekit = `apps/${slug}/ios/App/Products.storekit`;
  if (fs.existsSync(iapJson)) {
    const cfg = readJSON(iapJson);
    out.source = iapJson;
    if (cfg.bundleId && bundleId && cfg.bundleId !== bundleId) {
      problems.push(`${iapJson} says bundleId ${cfg.bundleId}, qa.json says ${bundleId}`);
    }
    out.group = cfg.group ?? null;
    out.baseTerritory = cfg.baseTerritory ?? "USA";
    if (cfg.reviewScreenshot) out.reviewScreenshot = cfg.reviewScreenshot;
    for (const p of cfg.products ?? []) {
      if (p.type === "nonConsumable") out.oneTime.push({ reviewNote: reviewNote(p.displayName), ...p });
      else out.subscriptions.push(p);
    }
  } else if (fs.existsSync(storekit)) {
    const sk = readJSON(storekit);
    out.source = storekit;
    for (const p of sk.products ?? []) {
      const loc = english(p.localizations);
      if (p.type !== "NonConsumable") {
        problems.push(`${p.productID} is ${p.type}; the factory sells nothing that runs out, so only NonConsumable is created`);
        continue;
      }
      out.oneTime.push({
        productId: p.productID,
        name: p.referenceName,
        displayName: loc.displayName,
        description: loc.description,
        price: p.displayPrice,
        familySharable: p.familyShareable ?? false,
        reviewNote: reviewNote(loc.displayName),
      });
    }
    if ((sk.nonRenewingSubscriptions ?? []).length) problems.push("non-renewing subscriptions are not automated");
    const groups = sk.subscriptionGroups ?? [];
    if (groups.length > 1) problems.push(`${groups.length} subscription groups; the factory uses one`);
    for (const g of groups.slice(0, 1)) {
      out.group = { referenceName: g.name, displayName: english(g.localizations).displayName ?? g.name };
      for (const s of g.subscriptions ?? []) {
        const loc = english(s.localizations);
        const offer = s.introductoryOffer;
        if (offer && offer.paymentMode !== "free") {
          problems.push(`${s.productID}: only free-trial introductory offers are automated, not ${offer.paymentMode}`);
        }
        out.subscriptions.push({
          productId: s.productID,
          name: s.referenceName,
          displayName: loc.displayName,
          description: loc.description,
          subscriptionPeriod: PERIOD[s.recurringSubscriptionPeriod] ?? `?${s.recurringSubscriptionPeriod}`,
          price: s.displayPrice,
          familySharable: s.familyShareable ?? false,
          reviewNote: reviewNote(loc.displayName),
          introOffer: offer?.paymentMode === "free"
            ? { duration: OFFER_DURATION[offer.subscriptionPeriod] ?? `?${offer.subscriptionPeriod}`, offerMode: "FREE_TRIAL", numberOfPeriods: offer.numberOfPeriods ?? 1 }
            : undefined,
        });
      }
    }
  } else {
    out.source = null; // an app with no StoreKit file sells nothing, which is allowed
  }

  // Apple's limits. Hitting one mid-run leaves half a product behind, so every product is
  // checked before anything touches the API.
  const len = (v) => [...(v ?? "")].length;
  const cap = (label, value, max, min = 0) => {
    if (len(value) > max || len(value) < min) {
      problems.push(`${label} is ${len(value)} characters, ${len(value) > max ? `max ${max}` : `min ${min}`}: "${value ?? ""}"`);
    }
  };
  if (out.group) cap("subscription group display name", out.group.displayName, LIMITS.groupDisplayName, 1);
  for (const [kind, list] of [["subscription", out.subscriptions], ["oneTime", out.oneTime]]) {
    for (const p of list) {
      if (!/^[A-Za-z0-9._-]+$/.test(p.productId ?? "")) problems.push(`product id "${p.productId}" has characters Apple rejects`);
      cap(`${p.productId} product id`, p.productId, LIMITS.productId);
      cap(`${p.productId} reference name`, p.name, LIMITS.referenceName, 1);
      cap(`${p.productId} display name`, p.displayName, LIMITS[kind].displayName, 2);
      cap(`${p.productId} description`, p.description, LIMITS[kind].description, 1);
      if (!/^\d+(\.\d{1,2})?$/.test(String(p.price ?? ""))) problems.push(`${p.productId} price "${p.price}" is not a price`);
      if (String(p.subscriptionPeriod ?? "").startsWith("?")) problems.push(`${p.productId} period ${p.subscriptionPeriod.slice(1)} is not one Apple sells`);
    }
  }
  if ((out.subscriptions.length || out.oneTime.length) && !out.reviewScreenshot) {
    problems.push(`no review screenshot: App Review needs the paywall, and store/screenshots/en-US has none to use`);
  }
  return out;
}

if (import.meta.url === pathToFileURL(process.argv[1] ?? "").href) {
  const slug = process.argv[2];
  if (!slug) {
    console.error("usage: products.mjs <slug>");
    process.exit(1);
  }
  const p = loadProducts(slug);
  console.log(`${slug}: ${p.subscriptions.length} subscription(s), ${p.oneTime.length} one-time, from ${p.source ?? "nothing (sells nothing)"}`);
  for (const s of p.subscriptions) console.log(`  sub      ${s.productId}  ${s.price}  ${s.subscriptionPeriod}${s.introOffer ? `  trial ${s.introOffer.duration}` : ""}  "${s.displayName}"`);
  for (const o of p.oneTime) console.log(`  one-time ${o.productId}  ${o.price}  "${o.displayName}" — "${o.description}"`);
  if (p.reviewScreenshot) console.log(`  review screenshot ${p.reviewScreenshot}`);
  if (p.problems.length) {
    console.error(`\nApp Store Connect would reject:`);
    for (const x of p.problems) console.error(`  · ${x}`);
    process.exit(1);
  }
}
