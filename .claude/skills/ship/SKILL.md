---
name: ship
description: Produce App Store screenshots, ASO metadata, privacy and support pages, then upload with fastlane and submit. Use for "screenshots", "metadata", "submit", "upload", "ship <slug>".
---

# /ship <slug>

Requires a built app (`STATUS.md` says `built`). Output goes to `apps/<slug>/store/` and `the starhiveconcept-site repo's site/<slug>/`.

1. **Raw captures.** Boot the 6.7" simulator, run the app, and capture five screens in the order a new user meets them: onboarding hook, the core screen with real-looking data, the moment of value, a second feature, the paywall. `tools/sim.sh shot … store/raw/0N.png`. Seed the app with believable example data first; empty screens do not sell.
2. **Compose.** Write `store/screenshots.json` (background, textColor, accent, five shots with a title under 40 characters and an optional subtitle) and run `node tools/screenshots/compose.mjs store/screenshots.json store/screenshots/6.7`. Read every output PNG. Titles state a benefit, not a feature; the first one is the promise from SPEC.md.
3. **Metadata.** Run `/aso-optimize` with the spec and the leader's complaints as context. Save into `store/metadata/en-US/`: `name.txt` (≤30), `subtitle.txt` (≤30), `keywords.txt` (≤100, comma-separated, no words already in name or subtitle), `description.txt`, `promotional_text.txt` (≤170), `release_notes.txt`, `support_url.txt`, `privacy_url.txt`. Check every limit with `wc -c`.
4. **Pages.** Generate `the starhiveconcept-site repo's site/<slug>/index.html` (landing, can be minimal for now), `the starhiveconcept-site repo's site/<slug>/privacy/index.html` and `the starhiveconcept-site repo's site/<slug>/support/index.html`. Plain HTML, no build step; GitHub Pages serves `sites/` from `main`.
5. **Upload.** Needs the values from `tools/setup-keys.sh` (App Store Connect key, team, review contact; fastlane loads `tools/fastlane/.env` itself) and the app record in App Store Connect (create it with `fastlane produce` from `tools/fastlane`). Then `cd tools/fastlane && APP_DIR=../../apps/<slug>/ios SCHEME=<Target> BUNDLE_ID=<bundle> fastlane beta` for TestFlight, `fastlane release` to push metadata, screenshots and submit for review. If the keys are missing, stop here, list exactly what is missing, and leave everything else ready.
6. Done means: App Store Connect shows "Waiting for Review". Update STATUS.md (`stage: submitted`, build number, date) and commit.
