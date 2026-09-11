#!/usr/bin/env node
/**
 * Take an app's in-app purchases from nothing to "Ready to Submit", without a browser.
 *
 *   node tools/asc/iap.mjs <slug>            # dry run: prints the plan, changes nothing
 *   node tools/asc/iap.mjs <slug> --apply    # do it
 *
 * What to create comes from tools/asc/products.mjs: the app's ios/App/Products.storekit, or
 * apps/<slug>/iap.json where one exists. Credentials: see tools/asc/asc.mjs.
 *
 * app-submit runs this with --apply before it uploads, so the products exist by the time the
 * owner makes a sandbox purchase on TestFlight.
 *
 * Subscriptions: the group and its localization, each subscription and its localization, the
 * price in every territory, the introductory offer in every territory, the review screenshot.
 * One-time unlocks: the product, its localization, availability, a price schedule whose other
 * territories Apple equalizes from the base price, the review screenshot. Anything missing one
 * of these sits in "Missing Metadata" and takes the whole app version down with it.
 *
 * Why this is not a fastlane lane: Spaceship has no subscription models at all, so fastlane
 * cannot touch in-app purchases.
 *
 * Everything is idempotent — anything that already exists is reused, never duplicated. With
 * --apply, anything left unfinished exits 2, so CI cannot report success over half a product.
 *
 * The one thing Apple will not let any of this touch is creating the app record itself.
 */
import fs from "node:fs";
import path from "node:path";
import crypto from "node:crypto";
import { asc, ascAll, ascMaybe, findApp, recordInstructions } from "./asc.mjs";
import { loadProducts } from "./products.mjs";

const [slug, ...flags] = process.argv.slice(2);
const apply = flags.includes("--apply");
if (!slug) {
  console.error("usage: iap.mjs <slug> [--apply]");
  process.exit(1);
}

const cfg = loadProducts(slug);
if (cfg.problems.length) {
  console.error(`${slug}'s products have values App Store Connect will reject (${cfg.source}):\n`);
  for (const p of cfg.problems) console.error(`  · ${p}`);
  process.exit(1);
}
if (!cfg.subscriptions.length && !cfg.oneTime.length) {
  console.log(`${slug} sells nothing (${cfg.source ?? "no Products.storekit"}); no in-app purchases to create.`);
  process.exit(0);
}

const money = (p) => `${p.attributes.customerPrice} ${p.relationships?.territory?.data?.id ?? ""}`.trim();
let created = 0;
let reused = 0;
const todo = [];

console.log(apply ? "APPLYING to App Store Connect\n" : "DRY RUN — nothing will be changed (pass --apply)\n");
console.log(`products from ${cfg.source}`);

// ── the app ───────────────────────────────────────────────────────────────────
const app = await findApp(cfg.bundleId);
if (!app) {
  console.error(`No app record for ${cfg.bundleId}. Apple does not allow creating one through the API;
create it once, then run this again:

${recordInstructions({ bundleId: cfg.bundleId, name: cfg.appName, sku: cfg.bundleId })}`);
  process.exit(1);
}
console.log(`app    ${app.attributes.name}  id ${app.id}\n`);

/** Reserve, upload and commit a review screenshot; `kind` is the resource type's stem. */
async function uploadReviewScreenshot(kind, relName, relType, ownerId, file) {
  const bytes = fs.readFileSync(file);
  const type = `${kind}AppStoreReviewScreenshots`;
  const reserved = (await asc("POST", `/${type}`, {
    data: {
      type,
      attributes: { fileName: path.basename(file), fileSize: bytes.length },
      relationships: { [relName]: { data: { type: relType, id: ownerId } } },
    },
  })).data;

  for (const op of reserved.attributes.uploadOperations ?? []) {
    const headers = {};
    for (const h of op.requestHeaders ?? []) headers[h.name] = h.value;
    const chunk = bytes.subarray(op.offset, op.offset + op.length);
    const put = await fetch(op.url, { method: op.method, headers, body: chunk });
    if (!put.ok) throw new Error(`screenshot upload failed: ${put.status}`);
  }

  await asc("PATCH", `/${type}/${reserved.id}`, {
    data: {
      type,
      id: reserved.id,
      attributes: {
        uploaded: true,
        sourceFileChecksum: crypto.createHash("md5").update(bytes).digest("hex"),
      },
    },
  });
}

// ── subscriptions ─────────────────────────────────────────────────────────────
async function subscriptions() {
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
    console.log("\nDry run: the subscriptions below the group need it to exist first.");
    return;
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

  const existingSubs = await ascAll(`/subscriptionGroups/${group.id}/subscriptions?limit=200`);

  for (const p of cfg.subscriptions) {
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

    // ── availability ──────────────────────────────────────────────────────────
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

    // ── price, in every territory ─────────────────────────────────────────────
    // The website lets you set one price and equalizes the rest. The API has no such call for
    // subscriptions: every territory needs its own POST. That tedium is exactly what a script
    // is for. A price point id is base64 of {"s":<subscription>,"t":<territory>,"p":<point>},
    // which is the cheapest way to know which territory a point belongs to.
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
    // hand in the website, leaves a handful of territories covered and the rest silently
    // unpriced. Compare against the territory list and fill the gaps.
    if (pricedIn.size >= 170) {
      console.log(`  price        reuse   already set in ${pricedIn.size} territories`);
      reused++;
    } else {
      const base = cfg.baseTerritory;
      const points = await ascAll(`/subscriptions/${sub.id}/pricePoints?filter[territory]=${base}&limit=200`);
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

      // One base point expands into an equalized point per territory — Apple's own, so the
      // result matches what the website would have set.
      const equalized = await ascAll(`/subscriptionPricePoints/${point.id}/equalizations?limit=200`);
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

    // ── introductory offer ────────────────────────────────────────────────────
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

    // ── review screenshot ─────────────────────────────────────────────────────
    // A subscription without one sits in "Missing Metadata" and blocks the whole version.
    await reviewScreenshot(p, "subscription", "subscriptions", sub.id, `/subscriptions/${sub.id}/appStoreReviewScreenshot`);
  }
}

async function reviewScreenshot(p, kind, relType, ownerId, currentUrl) {
  const shotPath = p.reviewScreenshot ?? cfg.reviewScreenshot;
  const file = path.resolve(shotPath);
  const have = await ascMaybe(currentUrl).catch(() => null);
  if (have) {
    console.log(`  screenshot   reuse   already attached`);
    reused++;
  } else if (!fs.existsSync(file)) {
    console.log(`  screenshot   SKIP    ${shotPath} does not exist`);
    todo.push(`${p.productId}: review screenshot missing at ${shotPath}`);
  } else if (!apply) {
    console.log(`  screenshot   upload  ${shotPath}`);
  } else {
    const relName = kind === "subscription" ? "subscription" : "inAppPurchaseV2";
    await uploadReviewScreenshot(kind, relName, relType, ownerId, file);
    console.log(`  screenshot   uploaded  ${path.basename(file)}`);
    created++;
  }
}

// ── one-time unlocks ──────────────────────────────────────────────────────────
async function oneTime() {
  const existing = await ascAll(`/apps/${app.id}/inAppPurchasesV2?limit=200`);

  for (const p of cfg.oneTime) {
    console.log(`\n── ${p.productId}  (one-time)`);
    let iap = existing.find((x) => x.attributes.productId === p.productId);
    if (iap) {
      console.log(`  product      reuse   id ${iap.id}  (${iap.attributes.state})`);
      reused++;
    } else if (!apply) {
      console.log(`  product      create  ${p.name}  NON_CONSUMABLE  ${p.price}`);
    } else {
      iap = (await asc("POST", "/v2/inAppPurchases", {
        data: {
          type: "inAppPurchases",
          attributes: {
            name: p.name,
            productId: p.productId,
            inAppPurchaseType: "NON_CONSUMABLE",
            reviewNote: p.reviewNote ?? undefined,
            familySharable: p.familySharable ?? false,
          },
          relationships: { app: { data: { type: "apps", id: app.id } } },
        },
      })).data;
      console.log(`  product      created  id ${iap.id}`);
      created++;
    }
    if (!iap) continue; // dry run

    // Localization — the name and description a customer sees on the purchase sheet.
    {
      const locs = await ascAll(`/v2/inAppPurchases/${iap.id}/inAppPurchaseLocalizations?limit=200`);
      if (locs.some((l) => l.attributes.locale === "en-US")) {
        reused++;
      } else if (apply) {
        await asc("POST", "/inAppPurchaseLocalizations", {
          data: {
            type: "inAppPurchaseLocalizations",
            attributes: { name: p.displayName, description: p.description, locale: "en-US" },
            relationships: { inAppPurchaseV2: { data: { type: "inAppPurchases", id: iap.id } } },
          },
        });
        console.log(`  localization created  en-US`);
        created++;
      } else {
        console.log(`  localization create  en-US`);
      }
    }

    // Availability before price, for the same reason as a subscription's.
    {
      const have = await ascMaybe(`/v2/inAppPurchases/${iap.id}/inAppPurchaseAvailability`).catch(() => null);
      if (have) {
        console.log(`  availability reuse   already set`);
        reused++;
      } else if (!apply) {
        console.log(`  availability set     all territories`);
      } else {
        const territories = await ascAll("/territories?limit=200");
        await asc("POST", "/inAppPurchaseAvailabilities", {
          data: {
            type: "inAppPurchaseAvailabilities",
            attributes: { availableInNewTerritories: true },
            relationships: {
              inAppPurchase: { data: { type: "inAppPurchases", id: iap.id } },
              availableTerritories: { data: territories.map((t) => ({ type: "territories", id: t.id })) },
            },
          },
        });
        console.log(`  availability set     ${territories.length} territories`);
        created++;
      }
    }

    // Price. Unlike a subscription, a one-time purchase takes a schedule: one manual price in
    // the base territory, and Apple equalizes every other territory from it automatically.
    {
      const schedule = await ascMaybe(`/v2/inAppPurchases/${iap.id}/iapPriceSchedule`).catch(() => null);
      const manual = schedule
        ? await ascAll(`/inAppPurchasePriceSchedules/${schedule.id}/manualPrices?limit=5`).catch(() => [])
        : [];
      if (manual.length) {
        console.log(`  price        reuse   schedule already set`);
        reused++;
      } else {
        const base = cfg.baseTerritory;
        const points = await ascAll(`/v2/inAppPurchases/${iap.id}/pricePoints?filter[territory]=${base}&limit=200`);
        const want = String(p.price);
        const point = points.find((pp) => Number(pp.attributes.customerPrice) === Number(want));
        if (!point) {
          const near = points
            .map((pp) => Number(pp.attributes.customerPrice))
            .sort((a, b) => Math.abs(a - Number(want)) - Math.abs(b - Number(want)))
            .slice(0, 5);
          console.log(`  price        SKIP    no ${base} price point at ${want}. Nearest: ${near.join(", ")}`);
          todo.push(`${p.productId}: pick a valid ${base} price (tried ${want})`);
        } else if (!apply) {
          console.log(`  price        set     ${want} ${base}, the rest equalized by Apple`);
        } else {
          await asc("POST", "/inAppPurchasePriceSchedules", {
            data: {
              type: "inAppPurchasePriceSchedules",
              relationships: {
                inAppPurchase: { data: { type: "inAppPurchases", id: iap.id } },
                baseTerritory: { data: { type: "territories", id: base } },
                manualPrices: { data: [{ type: "inAppPurchasePrices", id: "${price}" }] },
              },
            },
            included: [{
              type: "inAppPurchasePrices",
              id: "${price}",
              attributes: { startDate: null },
              relationships: {
                inAppPurchaseV2: { data: { type: "inAppPurchases", id: iap.id } },
                inAppPurchasePricePoint: { data: { type: "inAppPurchasePricePoints", id: point.id } },
              },
            }],
          });
          console.log(`  price        set     ${want} ${base}, the rest equalized by Apple`);
          created++;
        }
      }
    }

    await reviewScreenshot(p, "inAppPurchase", "inAppPurchases", iap.id, `/v2/inAppPurchases/${iap.id}/appStoreReviewScreenshot`);

    if (apply) {
      // Apple processes the review screenshot after the upload is committed, and the product
      // reads Missing Metadata until it has: Tidepour's did for a few seconds, then became
      // Ready to Submit. Give it two minutes before calling anything missing.
      let now;
      for (let i = 0; i < 12; i++) {
        now = (await asc("GET", `/v2/inAppPurchases/${iap.id}`)).data.attributes.state;
        if (now !== "MISSING_METADATA") break;
        await new Promise((r) => setTimeout(r, 10_000));
      }
      console.log(`  state        ${now}`);
      if (now === "MISSING_METADATA") todo.push(`${p.productId}: still Missing Metadata in App Store Connect after two minutes`);
    }
  }
}

if (cfg.subscriptions.length) await subscriptions();
if (cfg.oneTime.length) await oneTime();

// ── report ────────────────────────────────────────────────────────────────────
console.log(`\n${apply ? `${created} created, ${reused} already existed.` : "Dry run complete."}`);
if (todo.length) {
  console.log("\nNeeds attention:");
  for (const t of todo) console.log(`  · ${t}`);
}
if (apply) {
  console.log(`
Check the states at
  https://appstoreconnect.apple.com/apps/${app.id}/distribution/iaps
Anything still reading "Missing Metadata" will block the version at submission.`);
  if (todo.length) process.exit(2);
}
