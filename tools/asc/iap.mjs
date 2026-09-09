#!/usr/bin/env node
/**
 * Take an app's in-app purchases from nothing to "Ready to Submit", without a browser.
 *
 *   node tools/asc/iap.mjs <slug>            # dry run: prints the plan, changes nothing
 *   node tools/asc/iap.mjs <slug> --apply    # do it
 *
 * Reads apps/<slug>/iap.json. Credentials come from the same environment the Fastfile uses:
 * ASC_KEY_ID, ASC_ISSUER_ID, ASC_KEY_PATH (or ASC_KEY_P8 with the key's contents).
 *
 * Creates, in order: the subscription group and its localization, each subscription and its
 * localization, the price in every territory, the introductory offer in every territory, and
 * the review screenshot. A subscription missing any of these sits in "Missing Metadata" and
 * takes the whole app version down with it at submission.
 *
 * Why this is not a fastlane lane: Spaceship has no subscription models at all, so fastlane
 * cannot touch in-app purchases.
 *
 * Everything is idempotent — anything that already exists is reused, never duplicated.
 *
 * The one thing Apple will not let any of this touch is creating the app record itself.
 * Their documentation is explicit: "Don't use this API to create new apps; instead, create
 * new apps on the App Store Connect website." POST /v1/apps answers
 * "The resource 'apps' does not allow 'CREATE'".
 */
import fs from "node:fs";
import path from "node:path";
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
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

async function asc(method, url, body, { retries = 4 } = {}) {
  const full = url.startsWith("http") ? url : `${API}${url}`;
  for (let attempt = 0; ; attempt++) {
    const res = await fetch(full, {
      method,
      headers: { Authorization: `Bearer ${token()}`, "Content-Type": "application/json" },
      body: body ? JSON.stringify(body) : undefined,
    });
    if (res.status === 429 && attempt < retries) {
      await sleep(2000 * (attempt + 1));
      continue;
    }
    const text = await res.text();
    const json = text ? JSON.parse(text) : {};
    if (!res.ok) {
      const err = new Error(
        `${method} ${full.replace(API, "")} -> ${res.status}  ` +
        ((json.errors ?? []).map((e) => `${e.title}: ${e.detail}`).join("; ") || text)
      );
      err.status = res.status;
      err.errors = json.errors ?? [];
      throw err;
    }
    return json;
  }
}

/** Follow `links.next` so a 175-territory list is not silently truncated at the page size. */
async function ascAll(url) {
  const out = [];
  let next = url;
  while (next) {
    const page = await asc("GET", next);
    out.push(...(page.data ?? []));
    next = page.links?.next ?? null;
  }
  return out;
}

// App Store Connect's limits on subscription metadata. Hitting one of these mid-run leaves
// half a subscription behind, so check every product before touching the API at all.
{
  const problems = [];
  const cap = (label, value, max) => {
    if (value && [...value].length > max) {
      problems.push(`${label} is ${[...value].length} characters, max ${max}: "${value}"`);
    }
  };
  cap("group.displayName", cfg.group.displayName, 30);
  for (const p of cfg.products) {
    cap(`${p.productId} name`, p.name, 64);
    cap(`${p.productId} displayName`, p.displayName, 30);
    cap(`${p.productId} description`, p.description, 55);
  }
  if (problems.length) {
    console.error(`${cfgPath} has values App Store Connect will reject:\n`);
    for (const p of problems) console.error(`  · ${p}`);
    process.exit(1);
  }
}

const money = (p) => `${p.attributes.customerPrice} ${p.relationships?.territory?.data?.id ?? ""}`.trim();
let created = 0;
let reused = 0;
const todo = [];

console.log(apply ? "APPLYING to App Store Connect\n" : "DRY RUN — nothing will be changed (pass --apply)\n");

// ── the app ───────────────────────────────────────────────────────────────────
const apps = await asc("GET", `/apps?filter[bundleId]=${encodeURIComponent(cfg.bundleId)}&limit=1`);
if (!apps.data?.length) {
  console.error(`No app record for ${cfg.bundleId}.

Apple does not allow creating one through the API — their docs say to use the website, and
POST /v1/apps answers "The resource 'apps' does not allow 'CREATE'". Create it once:

  https://appstoreconnect.apple.com/apps  →  +  →  New App
    Platform   iOS
    Name       ${cfg.appName ?? "(the name from store/metadata/en-US/name.txt)"}
    Language   English (U.S.)
    Bundle ID  ${cfg.bundleId}
    SKU        ${cfg.bundleId}

then run this again.`);
  process.exit(1);
}
const app = apps.data[0];
console.log(`app    ${app.attributes.name}  id ${app.id}\n`);

// ── subscription group ────────────────────────────────────────────────────────
const groups = await ascAll(`/apps/${app.id}/subscriptionGroups?limit=200`);
let group = groups.find((g) => g.attributes.referenceName === cfg.group.referenceName);
if (group) {
  console.log(`group  reuse   "${cfg.group.referenceName}"  id ${group.id}`);
  reused++;
} else if (!apply) {
  console.log(`group  create  "${cfg.group.referenceName}"`);
} else {
  group = (await asc("POST", "/subscriptionGroups", {
    data: {
      type: "subscriptionGroups",
      attributes: { referenceName: cfg.group.referenceName },
      relationships: { app: { data: { type: "apps", id: app.id } } },
    },
  })).data;
  console.log(`group  created  id ${group.id}`);
  created++;
}
if (!group) {
  console.log("\nDry run stops here: everything below needs the group to exist.");
  process.exit(0);
}

// Group localization — the name a customer sees under Manage Subscriptions.
{
  const locs = await ascAll(`/subscriptionGroups/${group.id}/subscriptionGroupLocalizations?limit=200`);
  if (locs.some((l) => l.attributes.locale === "en-US")) {
    reused++;
  } else if (apply) {
    await asc("POST", "/subscriptionGroupLocalizations", {
      data: {
        type: "subscriptionGroupLocalizations",
        attributes: { name: cfg.group.displayName, locale: "en-US" },
        relationships: { subscriptionGroup: { data: { type: "subscriptionGroups", id: group.id } } },
      },
    });
    console.log(`group  localized en-US as "${cfg.group.displayName}"`);
    created++;
  } else {
    console.log(`group  localize en-US as "${cfg.group.displayName}"`);
  }
}

// ── subscriptions ─────────────────────────────────────────────────────────────
const existingSubs = await ascAll(`/subscriptionGroups/${group.id}/subscriptions?limit=200`);

for (const p of cfg.products) {
  console.log(`\n── ${p.productId}`);
  let sub = existingSubs.find((s) => s.attributes.productId === p.productId);

  if (sub) {
    console.log(`  sub          reuse   id ${sub.id}  (${sub.attributes.state})`);
    reused++;
  } else if (!apply) {
    console.log(`  sub          create  ${p.name}  ${p.subscriptionPeriod}`);
  } else {
    sub = (await asc("POST", "/subscriptions", {
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
    console.log(`  sub          created  id ${sub.id}`);
    created++;
  }

  if (!sub) continue; // dry run, nothing further to inspect

  // Checked independently of whether the subscription was just created: a run that failed
  // partway can leave a subscription with no localization, and it would never get one if
  // this only ran in the create branch.
  {
    const locs = await ascAll(`/subscriptions/${sub.id}/subscriptionLocalizations?limit=200`);
    if (locs.some((l) => l.attributes.locale === "en-US")) {
      reused++;
    } else if (apply) {
      await asc("POST", "/subscriptionLocalizations", {
        data: {
          type: "subscriptionLocalizations",
          attributes: { name: p.displayName, description: p.description, locale: "en-US" },
          relationships: { subscription: { data: { type: "subscriptions", id: sub.id } } },
        },
      });
      console.log(`  localization created  en-US`);
      created++;
    } else {
      console.log(`  localization create  en-US`);
    }
  }

  // ── availability ────────────────────────────────────────────────────────────
  // This has to come first. A subscription starts with no territories at all, and both
  // prices and introductory offers are attached per territory, so without it every one of
  // them fails — prices with an opaque "error processing the pricing information", offers
  // with the message that actually gives the game away: "You need to set up availabilities
  // first."
  {
    const have = await asc("GET", `/subscriptions/${sub.id}/subscriptionAvailability`).catch(() => ({ data: null }));
    if (have.data) {
      console.log(`  availability reuse   already set`);
      reused++;
    } else if (!apply) {
      console.log(`  availability set     all territories`);
    } else {
      const territories = await ascAll("/territories?limit=200");
      await asc("POST", "/subscriptionAvailabilities", {
        data: {
          type: "subscriptionAvailabilities",
          attributes: { availableInNewTerritories: true },
          relationships: {
            subscription: { data: { type: "subscriptions", id: sub.id } },
            availableTerritories: { data: territories.map((t) => ({ type: "territories", id: t.id })) },
          },
        },
      });
      console.log(`  availability set     ${territories.length} territories`);
      created++;
    }
  }

  // ── price, in every territory ───────────────────────────────────────────────
  // The website lets you set one price and equalizes the rest. The API has no such call:
  // every territory needs its own POST. That tedium is exactly what a script is for.
  // A price point id is base64 of {"s":<subscription>,"t":<territory>,"p":<point>}, which is
  // the cheapest way to know which territory a point belongs to without another request.
  const territoryOf = (pp) => {
    if (pp.relationships?.territory?.data?.id) return pp.relationships.territory.data.id;
    try {
      return JSON.parse(Buffer.from(pp.id, "base64").toString("utf8")).t ?? null;
    } catch {
      return null;
    }
  };

  const havePrices = await ascAll(`/subscriptions/${sub.id}/prices?limit=200&include=territory`);
  const pricedIn = new Set(havePrices.map((r) => r.relationships?.territory?.data?.id).filter(Boolean));
  // "Some prices exist" is not "prices are done": a run interrupted partway, or a price set by
  // hand in the website, leaves a handful of territories covered and the rest silently unpriced.
  // Compare against the territory list and fill the gaps.
  if (pricedIn.size >= 170) {
    console.log(`  price        reuse   already set in ${pricedIn.size} territories`);
    reused++;
  } else {
    const base = cfg.baseTerritory ?? "USA";
    const points = await ascAll(
      `/subscriptions/${sub.id}/pricePoints?filter[territory]=${base}&limit=200`
    );
    const want = String(p.price);
    const point = points.find((pp) => String(pp.attributes.customerPrice) === want);
    if (!point) {
      const near = points
        .map((pp) => Number(pp.attributes.customerPrice))
        .sort((a, b) => Math.abs(a - Number(want)) - Math.abs(b - Number(want)))
        .slice(0, 5);
      console.log(`  price        SKIP    no ${base} price point at ${want}. Nearest: ${near.join(", ")}`);
      todo.push(`${p.productId}: pick a valid ${base} price (tried ${want})`);
      continue;
    }

    // One base point expands into an equalized point per territory.
    const equalized = await ascAll(`/subscriptionPricePoints/${point.id}/equalizations?limit=200`);
    // Apple's own equalized points, so the result matches what the website would have set —
    // the website simply makes these calls for you.
    const all = [point, ...equalized].filter((pp) => {
      const terr = territoryOf(pp);
      return !terr || !pricedIn.has(terr);
    });
    if (!apply) {
      console.log(`  price        set     ${want} ${base} → ${all.length} territories${pricedIn.size ? ` (${pricedIn.size} already priced)` : ""}`);
    } else {
      let ok = 0;
      let failed = 0;
      for (const pp of all) {
        try {
          await asc("POST", "/subscriptionPrices", {
            data: {
              type: "subscriptionPrices",
              attributes: { startDate: null, preserveCurrentPrice: false },
              relationships: {
                subscription: { data: { type: "subscriptions", id: sub.id } },
                subscriptionPricePoint: { data: { type: "subscriptionPricePoints", id: pp.id } },
              },
            },
          });
          ok++;
        } catch (e) {
          failed++;
          if (failed <= 2) console.log(`    price ${money(pp)}: ${e.message.split("  ").pop()}`);
        }
      }
      console.log(`  price        set     ${want} ${base} → ${ok} territories${failed ? `, ${failed} failed` : ""}`);
      created += ok;
      if (failed) todo.push(`${p.productId}: ${failed} territories did not take a price`);
    }
  }

  // ── introductory offer ──────────────────────────────────────────────────────
  if (p.introOffer) {
    const haveOffers = await ascAll(`/subscriptions/${sub.id}/introductoryOffers?limit=200&include=territory`);
    const offeredIn = new Set(haveOffers.map((o) => o.relationships?.territory?.data?.id).filter(Boolean));
    if (offeredIn.size >= 170) {
      console.log(`  intro offer  reuse   already set in ${offeredIn.size} territories`);
      reused++;
    } else if (!apply) {
      console.log(`  intro offer  set     ${p.introOffer.duration} ${p.introOffer.offerMode}${offeredIn.size ? ` (${offeredIn.size} already have one)` : " in every territory"}`);
    } else {
      // Offer a trial only where the subscription actually has a price.
      const priced = await ascAll(`/subscriptions/${sub.id}/prices?limit=200&include=territory`);
      const ids = [...new Set(priced.map((t) => t.relationships?.territory?.data?.id).filter(Boolean))];
      const list = (ids.length ? ids : (await ascAll("/territories?limit=200")).map((t) => t.id))
        .filter((id) => !offeredIn.has(id));
      let ok = 0;
      let failed = 0;
      for (const territory of list) {
        try {
          await asc("POST", "/subscriptionIntroductoryOffers", {
            data: {
              type: "subscriptionIntroductoryOffers",
              attributes: {
                duration: p.introOffer.duration,
                offerMode: p.introOffer.offerMode,
                numberOfPeriods: p.introOffer.numberOfPeriods ?? 1,
                startDate: null,
                endDate: null,
              },
              relationships: {
                subscription: { data: { type: "subscriptions", id: sub.id } },
                territory: { data: { type: "territories", id: territory } },
              },
            },
          });
          ok++;
        } catch (e) {
          failed++;
          if (failed <= 2) console.log(`    offer ${territory}: ${e.message.split("  ").pop()}`);
        }
      }
      console.log(`  intro offer  set     ${p.introOffer.duration} ${p.introOffer.offerMode} → ${ok} territories${failed ? `, ${failed} failed` : ""}`);
      created += ok;
      if (failed) todo.push(`${p.productId}: ${failed} territories rejected the introductory offer`);
    }
  }

  // ── review screenshot ───────────────────────────────────────────────────────
  // A subscription without one sits in "Missing Metadata" and blocks the whole version.
  const shotPath = p.reviewScreenshot ?? cfg.reviewScreenshot;
  if (shotPath) {
    const file = path.resolve(shotPath);
    const have = await asc("GET", `/subscriptions/${sub.id}/appStoreReviewScreenshot`).catch(() => ({ data: null }));
    if (have.data) {
      console.log(`  screenshot   reuse   already attached`);
      reused++;
    } else if (!fs.existsSync(file)) {
      console.log(`  screenshot   SKIP    ${shotPath} does not exist`);
      todo.push(`${p.productId}: review screenshot missing at ${shotPath}`);
    } else if (!apply) {
      console.log(`  screenshot   upload  ${shotPath}`);
    } else {
      const bytes = fs.readFileSync(file);
      const reserved = (await asc("POST", "/subscriptionAppStoreReviewScreenshots", {
        data: {
          type: "subscriptionAppStoreReviewScreenshots",
          attributes: { fileName: path.basename(file), fileSize: bytes.length },
          relationships: { subscription: { data: { type: "subscriptions", id: sub.id } } },
        },
      })).data;

      for (const op of reserved.attributes.uploadOperations ?? []) {
        const headers = {};
        for (const h of op.requestHeaders ?? []) headers[h.name] = h.value;
        const chunk = bytes.subarray(op.offset, op.offset + op.length);
        const put = await fetch(op.url, { method: op.method, headers, body: chunk });
        if (!put.ok) throw new Error(`screenshot upload failed: ${put.status}`);
      }

      await asc("PATCH", `/subscriptionAppStoreReviewScreenshots/${reserved.id}`, {
        data: {
          type: "subscriptionAppStoreReviewScreenshots",
          id: reserved.id,
          attributes: {
            uploaded: true,
            sourceFileChecksum: crypto.createHash("md5").update(bytes).digest("hex"),
          },
        },
      });
      console.log(`  screenshot   uploaded  ${path.basename(file)}`);
      created++;
    }
  }
}

// ── report ────────────────────────────────────────────────────────────────────
console.log(`\n${apply ? `${created} created, ${reused} already existed.` : "Dry run complete."}`);
if (todo.length) {
  console.log("\nNeeds attention:");
  for (const t of todo) console.log(`  · ${t}`);
}
if (apply) {
  console.log(`
Check the states at
  https://appstoreconnect.apple.com/apps/${app.id}/distribution/subscriptions
Anything still reading "Missing Metadata" will block the version at submission.`);
}
