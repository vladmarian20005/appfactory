stage: uploaded, device pass failed
date: 2026-09-13
plan: PLAN.md · spec: SPEC.md · design: DESIGN.md · pack source: pack/build.mjs · pack review: pack/REVIEW.md

## The device pass, 13 September

The owner ran build 202609130850 from TestFlight and the paywall read **"$2.99 per day"**
for the weekly plan. The App Store reports a one-week period as seven days, and
`Product.periodDescription` in FactoryKit switched on the unit alone. The renewal terms under
the buttons said the same thing. A local `.storekit` file reports one week, so no simulator
capture could ever show it. Fixed in `FactoryKit/Sources/FactoryKit/Store.swift` (`PeriodLength`),
which also turns the live trial label "3-days free trial" into "3-day free trial". `app-verify`
is green on the fix for all four apps. **That build is not fit to submit.** A new upload is
needed before the device pass can be run again.

The listing went through the humanizer the same day, in all ten localizations. Two claims
were false and are fixed: the sheet reaches one easy question at edition 151, not the
hundredth, and a caption said "Nothing to buy" beside the paywall shot. The nine other
localizations are rewritten from the new English, so none of them says "the same ten for
everyone" any more.

## The second polish pass, 12 September

The second critic passed the look — Idea 5, Look 5, Voice 5 — and failed the app on the one
question a still cannot ask. Escalation 1 and Pull 1: all thirty rounds had the same
difficulty shape, nothing read the `difficulty` it printed on every sheet, and `Pack.swift`
dealt `dayNumber % 30`, so day 31 was day 1 again, in the same order, forever.

That is what this pass is about, and the look is untouched.

- **The desk** (`ios/App/Desk.swift`) decides everything the app serves. `Ladder` keyed on
  editions filed moves the sheet from 4 easy / 4 medium / 2 hard to 1 / 3 / 6 by edition 153;
  `Mastery` over 450 question ids picks the ten from the day's slate, weighted to what got
  past her and what she has never seen; `Run` holds what is at risk inside the ten; `Earned`
  opens the late edition at seven editions filed, eight questions at twenty-five, and her
  choice of section at sixty.
- **The pack grew from 300 questions to 450**, weighted 2 easy / 3 medium / 5 hard in the new
  rounds so the deep end of the ladder has material. `pack/build.py` is now `pack/build.mjs`,
  and it writes `REVIEW.md` as well as the JSON so the two cannot drift.
- **The edition ends on what is waiting**, not on a clock. The countdown is still there,
  smaller, under a line from `earned.next(after:)` or the section that keeps catching her.
- **Craft**: the verdict stamp is pinned to the bottom rule of the box she pressed and clamped
  to 190 pt, so it stops covering her answer at AX5; the Settings version footer clears the
  glass tab bar; every drawing has a dark variant, so the press reads as a silhouette on night
  stock instead of navy on navy.
- **The strips can see it now.** `qa.json` gained a four-rung `ladder` (editions 1, 10, 60,
  200), a `10-late-edition` screen, and retimed moments. `-editions N` seeds a reader with a
  real history so the deep end can be photographed.

### The one promise this pass changed

SPEC.md says "the same ten for everyone" and the first build implemented it as a modulo over
thirty rounds. TASTE.md's "content that knows what it has already served" and the critique's
fix 1 both require the opposite, so the daily edition is now **set on a date and personalised
by the desk**: the day fixes the slate, a reader with no history gets exactly the day's ten,
and from there the desk substitutes what has been catching her.

`store/metadata/en-US/` and `store/screenshots.json` are corrected, and since 13 September
so are the other nine localizations.

## The polish pass, 11 September

The critic failed the first build: it worked, it was compliant, and it was the template with
a trivia schema poured into it. DESIGN.md's newspaper was not in it at all. It is now — the
paper canvas with its grain and column rules, New York throughout, the ink press on every
answer, the edition printing itself when the round ends, the file as one number and a printed
month, the drawn art in place of every SF Symbol hero, the stamp icon, sound, and a front-page
share image. `tells.mjs` went from 17 hard tells and 5 smells to none.

The screenshots were recomposed from the newspaper build on 13 September.

## Where it stands

Everything the factory can do without a human has been done, in the cloud, on `macos-26`.

- **Builds and runs on iOS 26.** Xcode 26.6, iOS 26.5 simulator, iPhone 17 Pro Max. This is
  the version that matters: App Store Connect has rejected anything built with an older SDK
  since 28 April 2026, and the owner's Mac (Xcode 16.3) cannot produce a shippable binary.
- **`app-verify` green.** All ten screens in `qa.json` build, launch and render; no crash
  reports belonging to the app. Two `moments` — `-demo answer` and `-demo win` — film the ink
  press and the edition printing, since nothing in CI can touch a screen, and four `ladder`
  rungs show the sheet at editions 1, 10, 60 and 200.
- **`app-compliance` green.** Privacy manifest valid and matching the code, paywall carries
  the guideline 3.1.2 renewal terms, privacy and support URLs return 200, metadata inside
  every limit, screenshots 1320×2868 with no alpha, no placeholder text, no frozen font
  sizes, and the "no ads / no analytics" claims checked against the binary.
- **Screenshots current.** Six in `store/screenshots/en-US/`, composed on 13 September from
  the current build. Recompose once more to pick up balanced two-line headlines (`3661d7e`).
- **Listing written, in ten localizations.** `store/metadata/en-US/`: name 29/30, subtitle
  28/30, keywords 84/100, promo 167/170, description 2270/4000. Every claim checked against
  the source, and `listing-check.sh` is clean in all ten.
- **Privacy published.** `privacy.json` is the source of truth; the manifest, the App Store
  privacy answers and the policy page all generate from it, and drift fails the build. Live
  at https://starhiveconcept.com/quizday-privacy-policy-terms/
- **Signing ready.** Distribution certificate `Z8AF975P4B` created, a real password-protected
  p12 built from it, and `keychain-up.sh` verified to import it and find a valid identity.
  All 13 secrets are set on the appfactory repo.
- **Bundle id registered** in the Developer Portal: `com.starhiveconcept.quizday`.

## Blocked on the owner

The app record (6810429464) and all subscription records exist. Build 202609130850 is on
TestFlight and failed the device pass (see 13 September above).

1. **Upload the fixed build**: `gh workflow run app-submit.yml -f slug=quizday -f confirm=SUBMIT`.
2. **Recompose the screenshots** (optional, headlines only): `gh workflow run app-shots.yml -f slug=quizday`.
3. **Device pass** on the new build, on a phone: the weekly plan reads "per week", the daily
   reminder fires, haptics, the share sheet, and **a real sandbox purchase**. None of these can
   be checked on CI, because a scheme's StoreKit configuration is never honoured by a `simctl launch`.
4. **Submit**: set `device_tested` and `storekit_verified` in `state.json`, then
   `gh workflow run app-release.yml -f slug=quizday -f confirm=SUBMIT`.

## What the app is

- Today: one dated edition of ten, its slate fixed by the day and its ten chosen by the desk.
  Each answer is a printed line in a ruled box; pressing one sweeps ink across it, stamps a
  verdict from the night editor's pool, pencils the correction in on a miss, and sets the
  explanation and its source underneath. A run of ink lozenges under the tally is the thing
  that can be lost. Finishing prints the day's front page — score at 112 pt, the tally, a tier
  headline, shredded newsprint, the run in brass — ending on what is waiting, with the
  countdown under it.
- The late edition: earned at seven editions filed, free, five questions built from what got
  past her, growing to eight and then to her own choice of section.
- Scorecard: the run at 96 pt over one ledger line, the month printed in ink at three
  densities with today circled in pencil, a front-page share image, optional daily reminder.
- Practice (Pro): live rounds from the Open Trivia Database with per-category accuracy,
  weakest first. Network is used here and nowhere else.
- 450 original questions, each with an explanation, a source, a category and a difficulty that
  the selector actually reads. No ad SDK, no analytics, no account, no in-app currency.

## Not verified

- Real purchases. `-fakeProducts` drives the paywall for screenshots; only a TestFlight build
  with a sandbox account proves the real path.
- **The confetti in `moment-win.png` is a coin toss, and that is the tooling, not the app.**
  A `simctl io screenshot` of a page that is animating hard costs two to three seconds on a
  runner, and the burst lives 2.8 s, so it falls between two frames about as often as it lands
  in one. The strip reliably shows the tenth answer's ink sweep and the page mid-print; the
  burst itself is guaranteed only in `qa/03-result.png`, where `-stillFrames` freezes it at its
  peak, which is what that flag is for. Do not slow the win down to make it photograph better.
- Reminder delivery, haptics and the share sheet: all need hardware. The press's four beats —
  `Haptics.rigid` at the impression, `thud` under the stamp, `selection` on the tally square —
  and the tones that climb the round are wired as DESIGN.md specifies but have never been felt
  or heard: a CI simulator has no haptics and no audio device.

## Deviations from SPEC.md

- Bundle id is `com.starhiveconcept.quizday`, not `com.factory.quizday`: the scaffolder reads
  `BUNDLE_PREFIX` from the fastlane env, which is the owner's real prefix. Product ids follow.
- Streak is computed from the saved results rather than held in `@AppStorage`, so it cannot
  drift out of step with the calendar.
- **The daily ten are no longer literally identical for every reader.** See "The one promise
  this pass changed" above: the edition is set on a date, a first-time reader gets the day's
  slate exactly, and after that the desk sets it from what has caught her. TASTE.md's gate on
  content that knows what it has served and the critique's fix 1 both require it; keeping the
  stronger wording would have meant keeping `dayNumber % 30`.
- The pack is 450 questions, not the 300 the spec names — the ladder asks for six hard
  questions in a late edition and 90 hard questions would not have covered it.

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
