---
name: ship
description: Take a built app all the way to "Waiting for Review" — screenshots, metadata, privacy page, in-app purchases, TestFlight, submission. Use for "ship <slug>", "submit", "upload", "screenshots", "metadata", "release".
---

# /ship <slug>

Requires `apps/<slug>/STATUS.md` to say `built` or later.

**Almost none of this happens on the laptop.** The Xcode work runs on `macos-26` runners,
because App Store Connect has rejected anything built with an older SDK since 28 April 2026
and the owner's Mac cannot produce a shippable binary. Your job is to drive the workflows,
read what comes back, and stop at the two places a human is genuinely required.

Run the steps in order. Each is cheap to repeat and refuses to run twice destructively.

## 1. Screenshots and captures — cloud

```
gh workflow run app-shots.yml -f slug=<slug> -R vladmarian20005/appfactory
gh run watch $(gh run list -w app-shots.yml -L1 --json databaseId --jq '.[0].databaseId') -R vladmarian20005/appfactory
```

This builds the app, launches every screen in `apps/<slug>/qa.json`, proves each one actually
rendered, composes the marketing frames from `store/screenshots.json`, and commits them to
`store/screenshots/en-US/`.

If `store/screenshots.json` does not exist yet, write it first: `background` (a CSS gradient
is fine), `textColor`, `accent`, and five shots each with a `title` under 40 characters and an
optional `subtitle`. Titles state a benefit, not a feature; the first is the promise from
`SPEC.md`, and at least one should be the wedge stated plainly.

Then `git pull` and **Read every composed PNG.** A screenshot that is technically valid and
visually wrong is the failure mode here.

## 2. Metadata

Into `apps/<slug>/store/metadata/en-US/`, checking every limit with `wc -c`:

| file | limit |
| --- | --- |
| `name.txt` | 30 |
| `subtitle.txt` | 30 |
| `keywords.txt` | 100, comma-separated, no spaces after commas |
| `promotional_text.txt` | 170 |
| `description.txt` | 4000 |

Plus `release_notes.txt`, `support_url.txt`, `privacy_url.txt`.

Do not repeat words from the name or subtitle in `keywords.txt` — Apple indexes all three
together, so a repeat spends characters twice.

**Every claim in the description must be true of the binary.** If it says "no ads", grep for
an ad SDK before you write it. The compliance gate checks this, but finding it here is faster.

## 3. Privacy, terms and support page

`apps/<slug>/privacy.json` is the source of truth for what the app does with data. The
manifest, the App Store privacy answers and the published page all generate from it:

```
node tools/privacy/sync.mjs <slug>          # PrivacyInfo.xcprivacy + app_privacy_details.json
gh workflow run app-pages.yml -f slug=<slug> -R vladmarian20005/appfactory
```

`app-pages` publishes to the `starhiveconcept-site` repo, which deploys to Cloudflare Pages,
and polls the live URL until it answers 200. Do not move on until it does: `precheck` fails a
submission on a privacy URL that 404s, and it fails *after* the upload.

## 4. In-app purchases

```
node tools/asc/iap.mjs <slug>              # dry run: prints the plan
node tools/asc/iap.mjs <slug> --apply
```

Creates the subscription group, the products, their localizations, the price in all ~175
territories, the introductory offers, and the review screenshots. Idempotent, so re-run it
after fixing anything.

**This needs the app record to exist, and that is the one step nobody can automate.** Apple's
documentation says "Don't use this API to create new apps; instead, create new apps on the
App Store Connect website", and `POST /v1/apps` answers *"The resource 'apps' does not allow
'CREATE'"*. If the record is missing the script prints the exact five fields — hand them to
the owner and wait. The bundle id registers itself, via `fastlane create` in `tools/fastlane`.

Mind the limits it enforces before calling the API: subscription `description` is 55
characters, `displayName` 30.

## 5. Compliance gate

```
.github/scripts/compliance.sh <slug>
```

Privacy manifest valid and matching the code, paywall carrying the guideline 3.1.2 renewal
terms, privacy and support URLs live, metadata inside limits, screenshots 1320×2868 with no
alpha, no placeholder text, no frozen font sizes, and the listing's claims checked against the
binary. Fix the app, never the gate.

## 6. Upload to TestFlight — the gate

Stop and ask the owner before this. It puts a build on Apple's servers under their account.

```
gh workflow run app-submit.yml -f slug=<slug> -f confirm=SUBMIT -R vladmarian20005/appfactory
```

## 7. The device pass — the owner, on a phone

Post the checklist and wait. None of it can run in CI:

- the daily reminder actually fires
- haptics feel right
- the share sheet opens
- **a real sandbox purchase completes** — a scheme's StoreKit configuration is never honoured
  by a `simctl launch`, so no runner can buy anything

Set `storekit_verified` and `device_tested` in `apps/<slug>/state.json` only once the owner
confirms. The gate refuses to pass on your word.

## 8. Submit

```
gh workflow run app-release.yml -f slug=<slug> -f confirm=SUBMIT -R vladmarian20005/appfactory
```

Pushes metadata, screenshots and the App Privacy answers, then submits.

## Done means

App Store Connect reads **Waiting for Review**. Update `STATUS.md` (`stage: submitted`, the
build number, the date), and commit.

## When something fails

Read the run log before changing anything — `gh run view <id> --log-failed`. Most first-run
failures are Apple telling you a limit you did not know about, and the fix belongs in the
config file the script reads, not in the script.
