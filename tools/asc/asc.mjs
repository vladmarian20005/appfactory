/**
 * The App Store Connect client every tools/asc script shares: the API key's JWT, requests that
 * retry a 429 and page through `links.next`, and the handful of facts about an app that live
 * in this repository rather than in App Store Connect.
 *
 * Credentials come from the same environment the Fastfile uses: ASC_KEY_ID, ASC_ISSUER_ID,
 * and ASC_KEY_PATH or ASC_KEY_P8 (the key's contents). In CI they are repository secrets;
 * on a laptop, tools/fastlane/.env.
 */
import fs from "node:fs";
import crypto from "node:crypto";

const HOST = "https://api.appstoreconnect.apple.com";
export const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

function credentials() {
  const keyId = process.env.ASC_KEY_ID;
  const issuerId = process.env.ASC_ISSUER_ID;
  const keyPem =
    process.env.ASC_KEY_P8 || (process.env.ASC_KEY_PATH && fs.readFileSync(process.env.ASC_KEY_PATH, "utf8"));
  if (!keyId || !issuerId || !keyPem) {
    console.error("Set ASC_KEY_ID, ASC_ISSUER_ID and ASC_KEY_PATH (or ASC_KEY_P8). tools/fastlane/.env has them.");
    process.exit(1);
  }
  return { keyId, issuerId, keyPem };
}
let creds;

const b64 = (o) => Buffer.from(typeof o === "string" ? o : JSON.stringify(o)).toString("base64url");
function token() {
  creds ??= credentials();
  const now = Math.floor(Date.now() / 1000);
  const header = b64({ alg: "ES256", kid: creds.keyId, typ: "JWT" });
  const payload = b64({ iss: creds.issuerId, iat: now, exp: now + 900, aud: "appstoreconnect-v1" });
  const signer = crypto.createSign("SHA256");
  signer.update(`${header}.${payload}`);
  // ASC wants a JOSE (r||s) signature, not the DER encoding Node emits by default.
  const sig = signer.sign({ key: creds.keyPem, dsaEncoding: "ieee-p1363" }).toString("base64url");
  return `${header}.${payload}.${sig}`;
}

/** `/v2/...` and `/v1/...` go as written; a bare `/apps` means v1, which most resources are. */
const resolve = (url) => (url.startsWith("http") ? url : /^\/v\d+\//.test(url) ? `${HOST}${url}` : `${HOST}/v1${url}`);

export async function asc(method, url, body, { retries = 4 } = {}) {
  const full = resolve(url);
  for (let attempt = 0; ; attempt++) {
    const res = await fetch(full, {
      method,
      headers: { Authorization: `Bearer ${token()}`, "Content-Type": "application/json" },
      body: body ? JSON.stringify(body) : undefined,
    });
    if ((res.status === 429 || res.status >= 500) && attempt < retries) {
      await sleep(2000 * (attempt + 1));
      continue;
    }
    const text = await res.text();
    const json = text ? JSON.parse(text) : {};
    if (!res.ok) {
      const err = new Error(
        `${method} ${full.replace(HOST, "")} -> ${res.status}  ` +
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
export async function ascAll(url) {
  const out = [];
  let next = url;
  while (next) {
    const page = await asc("GET", next);
    out.push(...(page.data ?? []));
    next = page.links?.next ?? null;
  }
  return out;
}

/** GET that answers null instead of throwing when the resource is simply not there yet. */
export async function ascMaybe(url) {
  try {
    return (await asc("GET", url)).data ?? null;
  } catch (e) {
    if (e.status === 404) return null;
    throw e;
  }
}

/**
 * What App Store Connect needs to know about an app, from the files the build wrote:
 * the bundle id from qa.json, the store name from the English listing.
 */
export function appFacts(slug) {
  const qa = `apps/${slug}/qa.json`;
  if (!fs.existsSync(qa)) {
    console.error(`${qa} is missing, so the bundle id is unknown. The build writes it.`);
    process.exit(1);
  }
  const bundleId = JSON.parse(fs.readFileSync(qa, "utf8")).bundleId;
  const nameFile = `apps/${slug}/store/metadata/en-US/name.txt`;
  const name = fs.existsSync(nameFile) ? fs.readFileSync(nameFile, "utf8").trim() : null;
  return { slug, bundleId, name, sku: bundleId };
}

export async function findApp(bundleId) {
  const apps = await asc("GET", `/apps?filter[bundleId]=${encodeURIComponent(bundleId)}&limit=1`);
  return apps.data?.[0] ?? null;
}

/**
 * The one form Apple will not let the API fill in. Their documentation: "Don't use this API
 * to create new apps; instead, create new apps on the App Store Connect website."
 * POST /v1/apps answers "The resource 'apps' does not allow 'CREATE'".
 */
export function recordInstructions({ bundleId, name, sku }) {
  return [
    "https://appstoreconnect.apple.com/apps  →  +  →  New App",
    "  Platform   iOS",
    `  Name       ${name ?? "(the name from store/metadata/en-US/name.txt)"}`,
    "  Language   English (U.S.)",
    `  Bundle ID  ${bundleId}`,
    `  SKU        ${sku}`,
    "  Access     Full Access",
  ].join("\n");
}

/**
 * App Privacy is the other thing only a browser can set: the public API has no data-usage
 * endpoints at all (`/v1/appDataUsageCategories` does not exist), and fastlane's action for it
 * logs in with an Apple ID password, which this pipeline does not hold. The answers come from
 * store/app_privacy_details.json, which tools/privacy/sync.mjs generates from privacy.json.
 */
export function privacyInstructions(slug) {
  const file = `apps/${slug}/store/app_privacy_details.json`;
  if (!fs.existsSync(file)) return `App Privacy: ${file} is missing; run node tools/privacy/sync.mjs ${slug}.`;
  const entries = JSON.parse(fs.readFileSync(file, "utf8")).data_protections ?? [];
  if (entries.some((e) => e.data_protection === "DATA_NOT_COLLECTED")) {
    return "App Privacy  →  Get Started  →  \"No, we do not collect data from this app\"  →  Save  →  Publish";
  }
  const lines = entries
    .filter((e) => e.category)
    .map((e) => `  · ${e.category}: ${(e.purposes ?? []).join(", ") || "no purpose listed"}${(e.data_protections ?? []).length ? ` (${e.data_protections.join(", ")})` : ""}`);
  return ["App Privacy  →  Get Started  →  \"Yes, we collect data\", then declare exactly:", ...lines, "  then Publish"].join("\n");
}
