#!/usr/bin/env node
/**
 * Generate the two machine-readable privacy artifacts from apps/<slug>/privacy.json.
 *
 *   node tools/privacy/sync.mjs <slug>          write them
 *   node tools/privacy/sync.mjs <slug> --check  fail if they are out of date (for CI)
 *
 * Writes:
 *   apps/<slug>/ios/App/PrivacyInfo.xcprivacy      the bundle's privacy manifest
 *   apps/<slug>/store/app_privacy_details.json     the App Store "App Privacy" answers
 *
 * The third artifact, the published policy page, comes from tools/pages/build.mjs and the
 * same source file. Three descriptions of one app that are written by hand are three
 * descriptions that drift; App Review reads all of them.
 */
import fs from "node:fs";

const [slug, ...flags] = process.argv.slice(2);
if (!slug) {
  console.error("usage: sync.mjs <slug> [--check]");
  process.exit(1);
}
const check = flags.includes("--check");

const declPath = `apps/${slug}/privacy.json`;
if (!fs.existsSync(declPath)) {
  console.error(`${declPath} is missing.`);
  process.exit(1);
}
const d = JSON.parse(fs.readFileSync(declPath, "utf8"));

// ── PrivacyInfo.xcprivacy ─────────────────────────────────────────────────────
const apis = (d.requiredReasonAPIs ?? [])
  .map(
    (a) => `    <dict>
      <key>NSPrivacyAccessedAPIType</key>
      <string>${a.category}</string>
      <key>NSPrivacyAccessedAPITypeReasons</key>
      <array>
        <string>${a.reason}</string>
      </array>
    </dict>`
  )
  .join("\n");

const manifest = `<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<!--
  GENERATED from apps/${slug}/privacy.json by tools/privacy/sync.mjs. Do not edit by hand:
  edit privacy.json and re-run, or the manifest, the App Store answers and the published
  policy will describe three different apps.

  Required since 1 May 2024. App Store Connect rejects the upload itself, not the review, if
  the app touches a required-reason API without declaring it here.
${(d.requiredReasonAPIs ?? []).map((a) => `\n  ${a.category} / ${a.reason}\n    ${a.why}`).join("")}
-->
<plist version="1.0">
<dict>
  <key>NSPrivacyTracking</key>
  <${d.tracking ? "true" : "false"}/>

  <key>NSPrivacyTrackingDomains</key>
  <array/>

  <key>NSPrivacyCollectedDataTypes</key>
  <array${d.collects.length === 0 ? "/>" : ">\n" + d.collects.map((c) => `    <dict><key>NSPrivacyCollectedDataType</key><string>${c.type}</string></dict>`).join("\n") + "\n  </array>"}

  <key>NSPrivacyAccessedAPITypes</key>
  <array${apis ? ">\n" + apis + "\n  </array>" : "/>"}
</dict>
</plist>
`;

// ── App Store "App Privacy" answers ───────────────────────────────────────────
const details = {
  _comment:
    `GENERATED from apps/${slug}/privacy.json by tools/privacy/sync.mjs. Do not edit by hand. ` +
    `Uploaded by the fastlane release lane so nobody fills the questionnaire in a browser.`,
  data_protections:
    d.collects.length === 0
      ? [{ data_protection: "DATA_NOT_COLLECTED" }]
      : d.collects.map((c) => ({
          data_type: c.type,
          data_protections: c.protections ?? [],
          purposes: c.purposes ?? [],
        })),
};
const detailsJSON = JSON.stringify(details, null, 2) + "\n";

// ── write or check ────────────────────────────────────────────────────────────
const targets = [
  [`apps/${slug}/ios/App/PrivacyInfo.xcprivacy`, manifest],
  [`apps/${slug}/store/app_privacy_details.json`, detailsJSON],
];

let stale = 0;
for (const [file, content] of targets) {
  const current = fs.existsSync(file) ? fs.readFileSync(file, "utf8") : null;
  if (current === content) {
    console.log(`  up to date  ${file}`);
    continue;
  }
  if (check) {
    console.error(`::error::${file} is out of date with ${declPath}. Run: node tools/privacy/sync.mjs ${slug}`);
    stale++;
  } else {
    fs.mkdirSync(file.replace(/\/[^/]+$/, ""), { recursive: true });
    fs.writeFileSync(file, content);
    console.log(`  wrote       ${file}`);
  }
}

if (stale) process.exit(1);
console.log(check ? "privacy artifacts are in sync" : "privacy artifacts regenerated");
