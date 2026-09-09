#!/usr/bin/env node
/**
 * Generate an app's privacy policy, terms and support page from its privacy.json.
 *
 *   node tools/pages/build.mjs <slug> [outdir]
 *
 * Writes <outdir>/index.html, default apps/<slug>/store/page/index.html. app-pages.yml
 * copies it into the starhiveconcept-site repo as site/<pageSlug>/index.html, whose own
 * workflow deploys it to Cloudflare Pages.
 *
 * App Review needs a privacy policy URL that resolves, and `precheck` fails a submission on
 * one that 404s — after the upload. Generating the page from the same file that generates
 * PrivacyInfo.xcprivacy is what keeps the page, the manifest and the App Store answers from
 * describing three different apps.
 *
 * The markup and CSS match the pages already on starhiveconcept.com, so a generated page is
 * indistinguishable from the hand-written ones next to it.
 */
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const here = path.dirname(fileURLToPath(import.meta.url));
const [slug, outArg] = process.argv.slice(2);
if (!slug) {
  console.error("usage: build.mjs <slug> [outdir]");
  process.exit(1);
}

const declPath = `apps/${slug}/privacy.json`;
if (!fs.existsSync(declPath)) {
  console.error(`${declPath} is missing. It is the source of truth for what the app does with data.`);
  process.exit(1);
}
const d = JSON.parse(fs.readFileSync(declPath, "utf8"));
const outDir = outArg ?? `apps/${slug}/store/page`;

const e = (s) =>
  String(s ?? "").replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;").replace(/"/g, "&quot;");

const date = new Date(d.effectiveDate + "T00:00:00Z").toLocaleDateString("en-GB", {
  day: "numeric", month: "long", year: "numeric", timeZone: "UTC",
});

const app = e(d.appName);
const sections = [];
let n = 0;
const h2 = (title) => `  <h2>${++n}. ${title}</h2>`;
const p = (...lines) => lines.map((l) => `  <p>${l}</p>`).join("\n");
const ul = (items) => `  <ul>\n${items.map((i) => `    <li>${i}</li>`).join("\n")}\n  </ul>`;

// 1. What we collect
sections.push(
  h2("Information we collect") +
  "\n" +
  (d.collects.length === 0
    ? p(
        `None. ${app} has ${d.account ? "no user profile" : "no sign-up, no login and no user profile"}. ` +
        "We do not collect your name, your email address, your location, your contacts, your photos or any " +
        "device identifier. We operate no server that receives data from the app."
      )
    : p(`${app} collects the following, and nothing else:`) + "\n" + ul(d.collects.map(e)))
);

// 2. On-device storage
if (d.storesOnDevice?.length) {
  sections.push(
    h2("What the app stores on your device") + "\n" +
    p(`${app} keeps the following on your device, where it stays. It is included in your device backup if you use one, and it is deleted when you delete the app.`) +
    "\n" + ul(d.storesOnDevice.map(e))
  );
}

// 3. Network
sections.push(
  h2("Network use") + "\n" +
  (d.network?.length
    ? p(`${app} contacts the following services, and no others:`) + "\n" +
      ul(d.network.map((s) =>
        `<b>${e(s.service)}</b> (<a href="${e(s.url)}">${e(s.url)}</a>). ${e(s.why)} What is sent: ${e(s.sends)}`
      ))
    : p(`${app} makes no network requests. It works entirely offline.`))
);

// 4. Purchases
if (d.purchases) {
  const pu = d.purchases;
  sections.push(
    h2("Purchases") + "\n" +
    p(
      `${e(pu.name ?? "The paid tier")} is ${pu.type === "subscription" ? "an auto-renewing subscription" : "a one-time purchase"}` +
      `${pu.products?.length ? `, offered as ${pu.products.map(e).join(" and ")}` : ""}` +
      `${pu.trial ? `, with a ${e(pu.trial)}` : ""}. ` +
      `Payment is handled entirely by ${e(pu.processor ?? "Apple")} through your Apple Account. ` +
      `We never see or receive your payment details.` +
      (pu.type === "subscription"
        ? " A subscription renews automatically unless you cancel at least 24 hours before the end of the current period. " +
          "You can manage or cancel it at any time in your Apple Account settings."
        : "") +
      (pu.freeTier ? ` ${e(pu.freeTier)}` : "")
    )
  );
}

// 5. Notifications
if (d.notifications?.used) {
  sections.push(h2("Notifications") + "\n" + p(e(d.notifications.why)));
}

// 6. Ads, analytics, tracking
const none = [];
if (!d.ads) none.push("no advertising SDK and no ads of any kind");
if (!d.analytics) none.push("no analytics or crash-reporting SDK");
if (!d.tracking) none.push("no tracking, and no data shared with data brokers");
sections.push(
  h2("Advertising, analytics and third-party code") + "\n" +
  (none.length
    ? p(`${app} contains ${none.join(", ")}. We do not track you across apps or websites, and we do not use the Advertising Identifier (IDFA). Apple's App Tracking Transparency prompt does not appear because there is nothing to ask about.`)
    : p("See the App Store listing for this app's data disclosures."))
);

// 7. Children
sections.push(
  h2("Children") + "\n" +
  p(d.childDirected
    ? `${app} is directed at children and follows Apple's Kids Category rules: no third-party advertising, no analytics, and no external links outside a parental gate.`
    : `${app} is not directed at children under 13, and because it collects nothing, it holds no personal information about anyone, of any age.`)
);

// 8. Your control
sections.push(
  h2("Your control over your data") + "\n" +
  p(
    `Everything ${app} stores is on your device. Erase it from within the app, or delete the app, and it is gone. ` +
    "There is no account to close and no server-side copy for us to delete, because there is no server. " +
    "If you have a question about any of this, write to us at the address below."
  )
);

// 9. Terms
sections.push(
  h2("Terms of use") + "\n" +
  p(
    `By using ${app} you agree to these terms. ${app} is provided as it is, without warranty of any kind. ` +
    `${e(d.company)} is not liable for any loss arising from its use, to the extent the law allows.`,
    `Apple's <a href="https://www.apple.com/legal/internet-services/itunes/dev/stdeula/">Licensed Application End User License Agreement</a> also applies to your use of ${app}.`,
    `Do not attempt to decompile, resell or redistribute the app or its content.` +
    (d.attribution ? ` ${e(d.attribution)}` : "")
  )
);

// 10. Support
sections.push(
  `  <h2 id="support">${++n}. Support and contact</h2>\n` +
  p(
    `Questions, a bug, or a question you think is wrong? Write to us and a person will read it.`
  ) +
  `\n  <div class="contact">\n    <p><b>Email</b> &middot; <a href="mailto:${e(d.supportEmail)}">${e(d.supportEmail)}</a></p>\n` +
  `    <p>We aim to reply within two business days.</p>\n  </div>`
);

// 11. Changes
sections.push(
  h2("Changes to this policy") + "\n" +
  p(
    "If this policy changes, the new version appears on this page with a new effective date. " +
    "Material changes will also be noted in the app's release notes."
  )
);

const css = fs.readFileSync(path.join(here, "house.css"), "utf8");
const url = `${d.companyURL.replace(/\/$/, "")}/${d.pageSlug}/`;

const html = `<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Privacy Policy and Terms for ${app} - ${e(d.company.replace(/ Srl$/, ""))}</title>
<meta name="description" content="Privacy policy and terms of use for ${app}${d.collects.length === 0 ? `, by ${e(d.company)}. ${app} collects no personal data${!d.ads ? " and has no ads or trackers" : ""}.` : "."}">
<meta name="robots" content="index, follow">
<link rel="canonical" href="${e(url)}">
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Manrope:wght@400;500;600&family=Poppins:wght@600;700&display=swap">
<style>
${css}</style>
</head>
<body>
<div class="wrap">

  <header class="masthead">
    <a class="brand" href="${e(d.companyURL)}">${e(d.company.replace(/ Srl$/, ""))}</a>
    <h1>Privacy Policy and Terms for ${app}</h1>
    <p class="effective">Effective ${date}</p>
  </header>

${sections.join("\n\n")}

  <footer>
    <p>&copy; ${new Date(d.effectiveDate).getFullYear()} ${e(d.company)}. ${app} is a product of ${e(d.company)}.
    &middot; <a href="${e(d.companyURL)}">Back to ${e(d.companyURL.replace(/^https?:\/\//, "").replace(/\/$/, ""))}</a></p>
  </footer>

</div>
</body>
</html>
`;

fs.mkdirSync(outDir, { recursive: true });
const outFile = path.join(outDir, "index.html");
fs.writeFileSync(outFile, html);

// The app links straight to #support; a page without that anchor gives a dead Support link.
if (!html.includes('id="support"')) {
  console.error("::error::generated page has no #support anchor");
  process.exit(1);
}
console.log(`wrote ${outFile}  (${(html.length / 1024).toFixed(1)} KB, ${n} sections)`);
console.log(`  publishes to ${url}`);
