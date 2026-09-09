#!/usr/bin/env node
/**
 * Create an app's subscription group and its subscriptions in App Store Connect.
 *
 *   node tools/asc/iap.mjs <slug>              # dry run: says what it would do, changes nothing
 *   node tools/asc/iap.mjs <slug> --apply      # actually create
 *
 * Reads apps/<slug>/iap.json. Credentials come from the same environment the Fastfile uses:
 * ASC_KEY_ID, ASC_ISSUER_ID, ASC_KEY_PATH (or ASC_KEY_P8 with the key's contents).
 *
 * Why this is not a fastlane lane: Spaceship has no subscription models at all, so fastlane
 * cannot create in-app purchases. Without this, every first submission needs someone in a
 * browser building a subscription group by hand, and a version whose products are not
 * "Ready to Submit" is rejected outright.
 *
 * Idempotent: anything that already exists is reused, not duplicated.
 */
import fs from "node:fs";
import crypto from "node:crypto";

const [slug, ...flags] = process.argv.slice(2);
const apply = flags.includes("--apply");
if (!slug) {
  console.error("usage: iap.mjs <slug> [--apply]");
  process.exit(1);
}

const cfgPath = `apps/${slug}/iap.json`;
if (!fs.existsSync(cfgPath)) {
  console.error(`${cfgPath} is missing. It lists the subscription group and products to create.`);
  process.exit(1);
}
const cfg = JSON.parse(fs.readFileSync(cfgPath, "utf8"));

const KEY_ID = process.env.ASC_KEY_ID;
const ISSUER_ID = process.env.ASC_ISSUER_ID;
const keyPem = process.env.ASC_KEY_P8 ?? (process.env.ASC_KEY_PATH && fs.readFileSync(process.env.ASC_KEY_PATH, "utf8"));
if (!KEY_ID || !ISSUER_ID || !keyPem) {
  console.error("Set ASC_KEY_ID, ASC_ISSUER_ID and ASC_KEY_PATH (or ASC_KEY_P8). tools/fastlane/.env has them.");
  process.exit(1);
}

// ── auth ──────────────────────────────────────────────────────────────────────
const b64 = (o) => Buffer.from(typeof o === "string" ? o : JSON.stringify(o)).toString("base64url");
function token() {
  const now = Math.floor(Date.now() / 1000);
  const header = b64({ alg: "ES256", kid: KEY_ID, typ: "JWT" });
  const payload = b64({ iss: ISSUER_ID, iat: now, exp: now + 900, aud: "appstoreconnect-v1" });
  const signer = crypto.createSign("SHA256");
  signer.update(`${header}.${payload}`);
  // ASC wants a JOSE (r||s) signature, not the DER encoding Node emits by default.
  const sig = signer.sign({ key: keyPem, dsaEncoding: "ieee-p1363" }).toString("base64url");
  return `${header}.${payload}.${sig}`;
}

const API = "https://api.appstoreconnect.apple.com/v1";
async function asc(method, path, body) {
  const res = await fetch(path.startsWith("http") ? path : `${API}${path}`, {
    method,
    headers: {
      Authorization: `Bearer ${token()}`,
      "Content-Type": "application/json",
    },
    body: body ? JSON.stringify(body) : undefined,
  });
  const text = await res.text();
  const json = text ? JSON.parse(text) : {};
  if (!res.ok) {
    const detail = (json.errors ?? []).map((e) => `${e.title}: ${e.detail}`).join("; ") || text;
    throw new Error(`${method} ${path} -> ${res.status}  ${detail}`);
  }
  return json;
}

// ── go ────────────────────────────────────────────────────────────────────────
console.log(apply ? "APPLYING changes to App Store Connect" : "DRY RUN — nothing will be created (pass --apply)");
console.log();

const apps = await asc("GET", `/apps?filter[bundleId]=${encodeURIComponent(cfg.bundleId)}&limit=1`);
if (!apps.data?.length) {
  console.error(`No app record for ${cfg.bundleId}. Create it first: fastlane create in tools/fastlane.`);
  process.exit(1);
}
const app = apps.data[0];
console.log(`app  ${app.attributes.name}  (${cfg.bundleId})  id ${app.id}`);

// Subscription group
const groups = await asc("GET", `/apps/${app.id}/subscriptionGroups?limit=50`);
let group = groups.data?.find((g) => g.attributes.referenceName === cfg.group.referenceName);
if (group) {
  console.log(`group  reuse  "${cfg.group.referenceName}"  id ${group.id}`);
} else if (!apply) {
  console.log(`group  WOULD CREATE  "${cfg.group.referenceName}"`);
} else {
  group = (await asc("POST", "/subscriptionGroups", {
    data: {
      type: "subscriptionGroups",
      attributes: { referenceName: cfg.group.referenceName },
      relationships: { app: { data: { type: "apps", id: app.id } } },
    },
  })).data;
  console.log(`group  created  "${cfg.group.referenceName}"  id ${group.id}`);
}

if (!group) {
  console.log("\nStop: the rest needs the group to exist. Re-run with --apply.");
  process.exit(0);
}

// Group localization — the name customers see in Manage Subscriptions.
if (apply) {
  const locs = await asc("GET", `/subscriptionGroups/${group.id}/subscriptionGroupLocalizations?limit=50`);
  if (!locs.data?.some((l) => l.attributes.locale === "en-US")) {
    await asc("POST", "/subscriptionGroupLocalizations", {
      data: {
        type: "subscriptionGroupLocalizations",
        attributes: { name: cfg.group.displayName, locale: "en-US" },
        relationships: { subscriptionGroup: { data: { type: "subscriptionGroups", id: group.id } } },
      },
    });
    console.log(`group  localized en-US as "${cfg.group.displayName}"`);
  }
}

// Subscriptions
const existing = await asc("GET", `/subscriptionGroups/${group.id}/subscriptions?limit=200`);
for (const p of cfg.products) {
  const hit = existing.data?.find((s) => s.attributes.productId === p.productId);
  if (hit) {
    console.log(`sub    reuse  ${p.productId}  (${hit.attributes.state})`);
    continue;
  }
  if (!apply) {
    console.log(`sub    WOULD CREATE  ${p.productId}  ${p.name}  ${p.subscriptionPeriod}`);
    continue;
  }
  const sub = (await asc("POST", "/subscriptions", {
    data: {
      type: "subscriptions",
      attributes: {
        name: p.name,
        productId: p.productId,
        subscriptionPeriod: p.subscriptionPeriod,
        familySharable: p.familySharable ?? false,
        reviewNote: p.reviewNote ?? undefined,
      },
      relationships: { group: { data: { type: "subscriptionGroups", id: group.id } } },
    },
  })).data;
  console.log(`sub    created  ${p.productId}  id ${sub.id}`);

  await asc("POST", "/subscriptionLocalizations", {
    data: {
      type: "subscriptionLocalizations",
      attributes: { name: p.displayName, description: p.description, locale: "en-US" },
      relationships: { subscription: { data: { type: "subscriptions", id: sub.id } } },
    },
  });
  console.log(`       localized en-US`);
}

console.log(`
Still to do in App Store Connect, by hand:
  · Price for each subscription. The API needs an opaque pricePoint id per territory, and
    picking the wrong one silently sets the wrong price in 175 countries.
  · The introductory offer (${cfg.products.find((p) => p.trial)?.trial ?? "free trial"}), if the plan calls for one.
  · A screenshot for subscription review.
A version whose products are not "Ready to Submit" is rejected, so finish these before submitting.`);
