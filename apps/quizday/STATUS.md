stage: ready-to-submit
date: 2026-09-10
plan: PLAN.md · spec: SPEC.md · pack source: pack/build.py · pack review: pack/REVIEW.md

## Where it stands

Everything the factory can do without a human has been done, in the cloud, on `macos-26`.

- **Builds and runs on iOS 26.** Xcode 26.6, iOS 26.5 simulator, iPhone 17 Pro Max. This is
  the version that matters: App Store Connect has rejected anything built with an older SDK
  since 28 April 2026, and the owner's Mac (Xcode 16.3) cannot produce a shippable binary.
- **`app-verify` green.** All five screens in `qa.json` build, launch and render; no crash
  reports belonging to the app.
- **`app-compliance` green.** Privacy manifest valid and matching the code, paywall carries
  the guideline 3.1.2 renewal terms, privacy and support URLs return 200, metadata inside
  every limit, screenshots 1320×2868 with no alpha, no placeholder text, no frozen font
  sizes, and the "no ads / no analytics" claims checked against the binary.
- **`app-shots` green.** Five App Store screenshots captured on iOS 26 and composed in CI,
  committed to `store/screenshots/en-US/`.
- **Listing written.** `store/metadata/en-US/` — name 29/30, subtitle 28/30, keywords 84/100,
  promo 113/170, description 1624/4000. Every claim verified against the source.
- **Privacy published.** `privacy.json` is the source of truth; the manifest, the App Store
  privacy answers and the policy page all generate from it, and drift fails the build. Live
  at https://starhiveconcept.com/quizday-privacy-policy-terms/
- **Signing ready.** Distribution certificate `Z8AF975P4B` created, a real password-protected
  p12 built from it, and `keychain-up.sh` verified to import it and find a valid identity.
  All 13 secrets are set on the appfactory repo.
- **Bundle id registered** in the Developer Portal: `com.starhiveconcept.quizday`.

## Blocked on the owner

1. **Create the app record.** Apple's API does not allow it — verified against the live
   endpoint: *"The resource 'apps' does not allow 'CREATE'"*. One form, once:
   appstoreconnect.apple.com/apps → + → New App, iOS,
   name `Quizday: Daily Trivia, No Ads`, English (U.S.), bundle id and SKU
   `com.starhiveconcept.quizday`.
2. **Create the subscriptions**: `node tools/asc/iap.mjs quizday --apply` once the record
   exists. Then set the two prices ($2.99/week, $19.99/year), the 3-day introductory offer
   and the subscription review screenshot in App Store Connect — the API takes an opaque
   price-point id per territory and the wrong one silently misprices 175 countries.
3. **Upload**: `gh workflow run app-submit.yml -f slug=quizday -f confirm=SUBMIT`.
4. **Device pass** from TestFlight, on a phone: the daily reminder fires, haptics, the share
   sheet, and **a real sandbox purchase**. None of these can be checked on CI — a scheme's
   StoreKit configuration is never honoured by a `simctl launch`.
5. **Submit**: `gh workflow run app-release.yml -f slug=quizday -f confirm=SUBMIT`.

## What the app is

- Today: a date-seeded round of ten, identical for everyone, instant reveal with an
  explanation, a source and a report button; result screen with squares, streak and a
  countdown to tomorrow.
- Scorecard: streaks computed from saved results, month calendar shaded by score, plain-text
  share line, optional daily reminder.
- Practice (Pro): live rounds from the Open Trivia Database with per-category accuracy,
  weakest first. Network is used here and nowhere else.
- 300 original questions across 30 rounds, each with an explanation, a source, a category and
  a difficulty. No ad SDK, no analytics, no account, no in-app currency.

## Not verified

- Real purchases. `-fakeProducts` drives the paywall for screenshots; only a TestFlight build
  with a sandbox account proves the real path.
- Reminder delivery, haptics and the share sheet: all need hardware.

## Deviations from SPEC.md

- Bundle id is `com.starhiveconcept.quizday`, not `com.factory.quizday`: the scaffolder reads
  `BUNDLE_PREFIX` from the fastlane env, which is the owner's real prefix. Product ids follow.
- Streak is computed from the saved results rather than held in `@AppStorage`, so it cannot
  drift out of step with the calendar.

## Owner to do, unrelated to shipping

- Read `pack/REVIEW.md` and reject any question that looks wrong. A fix is a data change, not
  a release.
