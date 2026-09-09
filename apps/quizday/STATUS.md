stage: built
date: 2026-09-09
plan: PLAN.md · spec: SPEC.md · pack source: pack/build.py · pack review: pack/REVIEW.md

built:
  - Xcode project factory/apps/quizday/ios (target Quizday, bundle com.starhiveconcept.quizday), builds clean with no warnings and runs on the iPhone 15 Pro Max simulator
  - Today: date-seeded round (round 12 on 2026-09-09), ten questions, instant reveal with explanation, source and a report button, result screen with squares, streak and a live countdown to tomorrow
  - Scorecard: today's score, current and best streak, days played, month calendar shaded by score with month paging, share text, daily reminder toggle with a time picker
  - Practice (Pro): category and difficulty pickers, live rounds from the Open Trivia Database, per-category accuracy sorted weakest first, locked state with the Pro pitch for free users
  - Settings: kit rows plus days played, pack size, reported questions with a detail list, erase history, OpenTDB attribution
  - Content: 300 original questions in 30 rounds (App/questions.json), each with an explanation, a source, a category and a difficulty; every round ramps easy to hard; validated for duplicates, answer counts and field completeness by pack/build.py
  - No ad SDK, no analytics, no account, no in-app currency. Network is used only inside Practice.
  - Launch flags for tooling: -onboarded -sampleData -reset -pro -fakeProducts -screen <today|scorecard|practice|paywall|settings> -play -playStep <n> -reveal -answered <n> -practiceStart

verified on the simulator:
  - Cold start on a clean install with no crash; onboarding then Today
  - A full ten-question round saves and survives relaunch (10/10 on 2026-09-09 still shown after a cold start)
  - Empty state: no history shows 0 streak, 0 days played, an empty calendar and "Not played yet"
  - Practice fetches, decodes and renders a live round from the Open Trivia Database
  - Dark mode across Today, the question card and the Scorecard
  - Dynamic Type at accessibility-large: text wraps, nothing clips
  - Paywall with injected offers shows both products at $2.99 weekly and $19.99 yearly with the 3-day trial and the free-forever promise

fixed during QA:
  - The QA reset flag ran in a .task that raced TodayView's onAppear and could delete a result the view had just written; reset and seeding now run in the App initialiser, before any view appears
  - The calendar legend and the calendar cells used different opacities; both now come from one ScoreShade definition
  - factoryReviewPrompt fired on the root view and interrupted a question mid-round; it is still wired but now asks on the result screen, the natural moment

not verified:
  - Real purchases: the local StoreKit configuration only applies when Xcode launches the scheme, so a command-line launch shows "Products are not available right now" and the CTA stays disabled. Run the Quizday scheme from Xcode to test the sandbox purchase.
  - Reminder notification actually firing, haptics and the share sheet: all need a real device (the owner's Thursday test).
  - /ios-qa and /ios-design-review were not run: both need a physical iPhone over USB plus the DebugBridge package embedded in the app. Simulator QA above was run instead.

blocked:
  - TestFlight upload and submission: needs Apple Developer Program, App Store Connect API key (ASC_KEY_ID, ASC_ISSUER_ID, ASC_KEY_PATH) and TEAM_ID
  - Support and privacy pages at https://vladmarian20005.github.io/appmonkey/quizday/ do not exist yet; the repo is private, so Pages needs a public repo or another host

owner to do:
  - Read pack/REVIEW.md and reject any question that looks wrong; a fix is a data change, not a release
  - Thursday: device test (reminder fires, haptics, share sheet), then the submit approval

deviations from SPEC.md:
  - Bundle id is com.starhiveconcept.quizday, not com.factory.quizday: the scaffolder reads BUNDLE_PREFIX from the fastlane env, which is the owner's real prefix. Product ids follow it.
  - Streak is computed from the saved results rather than held in @AppStorage, so it cannot drift out of step with the calendar. @AppStorage still holds the reminder and practice settings.

next: /ship quizday
