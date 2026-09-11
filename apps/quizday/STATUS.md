stage: polished
date: 2026-09-11
plan: PLAN.md · spec: SPEC.md · design: DESIGN.md · pack source: pack/build.py · pack review: pack/REVIEW.md

## The polish pass, 11 September

The critic failed the first build: it worked, it was compliant, and it was the template with
a trivia schema poured into it. DESIGN.md's newspaper was not in it at all. It is now — the
paper canvas with its grain and column rules, New York throughout, the ink press on every
answer, the edition printing itself when the round ends, the file as one number and a printed
month, the drawn art in place of every SF Symbol hero, the stamp icon, sound, and a front-page
share image. `tells.mjs` went from 17 hard tells and 5 smells to none.

**One thing to redo before submitting: the App Store screenshots.** `store/screenshots/en-US/`
was composed from the old purple build, and `store/screenshots.json` now frames the captures
in the brand's newsprint instead. Re-run `app-shots` (or
`node tools/screenshots/compose.mjs apps/quizday/store/screenshots.json apps/quizday/store/screenshots/en-US`
over fresh `store/raw`) so the listing shows the app that ships. `app-compliance` should run
again after it.

## Where it stands

Everything the factory can do without a human has been done, in the cloud, on `macos-26`.

- **Builds and runs on iOS 26.** Xcode 26.6, iOS 26.5 simulator, iPhone 17 Pro Max. This is
  the version that matters: App Store Connect has rejected anything built with an older SDK
  since 28 April 2026, and the owner's Mac (Xcode 16.3) cannot produce a shippable binary.
- **`app-verify` green.** All eight screens in `qa.json` build, launch and render; no crash
  reports belonging to the app. Two `moments` — `-demo answer` and `-demo win` — film the ink
  press and the edition printing, since nothing in CI can touch a screen.
- **`app-compliance` green.** Privacy manifest valid and matching the code, paywall carries
  the guideline 3.1.2 renewal terms, privacy and support URLs return 200, metadata inside
  every limit, screenshots 1320×2868 with no alpha, no placeholder text, no frozen font
  sizes, and the "no ads / no analytics" claims checked against the binary.
- **`app-shots` needs re-running.** The five composed screenshots in `store/screenshots/en-US/`
  are of the pre-polish build; see the note above.
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

- Today: a date-seeded round of ten, identical for everyone. Each answer is a printed line in
  a ruled box; pressing one sweeps ink across it, stamps a verdict from the night editor's
  pool, pencils the correction in on a miss, and sets the explanation and its source
  underneath. Finishing prints the day's front page — score at 112 pt, the tally, a tier
  headline, shredded newsprint, the run in brass — with the countdown to tomorrow under a fold.
- Scorecard: the run at 96 pt over one ledger line, the month printed in ink at three
  densities with today circled in pencil, a front-page share image, optional daily reminder.
- Practice (Pro): live rounds from the Open Trivia Database with per-category accuracy,
  weakest first. Network is used here and nowhere else.
- 300 original questions across 30 rounds, each with an explanation, a source, a category and
  a difficulty. No ad SDK, no analytics, no account, no in-app currency.

## Not verified

- Real purchases. `-fakeProducts` drives the paywall for screenshots; only a TestFlight build
  with a sandbox account proves the real path.
- Reminder delivery, haptics and the share sheet: all need hardware. The press's four beats —
  `Haptics.rigid` at the impression, `thud` under the stamp, `selection` on the tally square —
  and the tones that climb the round are wired as DESIGN.md specifies but have never been felt
  or heard: a CI simulator has no haptics and no audio device.

## Deviations from SPEC.md

- Bundle id is `com.starhiveconcept.quizday`, not `com.factory.quizday`: the scaffolder reads
  `BUNDLE_PREFIX` from the fastlane env, which is the owner's real prefix. Product ids follow.
- Streak is computed from the saved results rather than held in `@AppStorage`, so it cannot
  drift out of step with the calendar.

## Deviations from DESIGN.md

- The calendar's middle density is `ink` at 0.70, not 0.62: at 0.62 the knocked-out score came
  out at 4.04:1, large-text only. The three-step ramp still reads as three.
- On a miss the printed answer inks in proof green as well as being circled, as `mock-1-play`
  shows it. DESIGN.md's beat table only inks the box she pressed.
- Display type stops growing at `accessibility2` and the verdict stamp at `xxLarge`. Every
  string the reader needs — answers, explanations, sources, datelines, buttons — scales the
  whole way.

## Owner to do, unrelated to shipping

- Read `pack/REVIEW.md` and reject any question that looks wrong. A fix is a data change, not
  a release.
