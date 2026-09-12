---
name: new-app
description: Scaffold an iOS app from the template and implement the screens from SPEC.md in the look DESIGN.md sets, building and checking it on the simulator. Use for "scaffold", "new app", "start building", "build <slug>".
---

# /new-app <slug> "<Display Name>"

Requires `apps/<slug>/SPEC.md` and `apps/<slug>/DESIGN.md`. If DESIGN.md is missing, follow
`.claude/skills/direct/SKILL.md` first — an app built without a direction comes out as the
template in a new color. Produces an app that builds, runs, renders every screen, and clears
`TASTE.md`.

Read `TASTE.md` before anything else. SPEC.md says **what** to build. DESIGN.md says **what it
is like**: the idea, the palette, the signature interaction, the reward, the voice, and three
mocks in `design/`. Build that. Where DESIGN.md is silent, decide the way it would.

You are most likely running on a `macos-26` GitHub runner with no GUI, no physical device and
no Xcode window. Everything below works there. Nothing below needs a human.

## Rules that are not negotiable

- **Commit *and push* after each screen works, never once at the end.** A commit alone does
  not save anything here: the repository you are committing into is on an ephemeral runner
  and is destroyed with it. `git pull --rebase origin "$GITHUB_REF_NAME" && git push origin
  HEAD:"$GITHUB_REF_NAME"`. A half-finished app on the branch is worth far more than three
  hours of work that no longer exists.
- **In the brand from the first line.** `AppBrand.swift` gets DESIGN.md's tokens before any
  screen exists, and every screen is written on `.brandBackground()` with `brandSurface`,
  `brandFont` and the palette. Never gray first and "styled later": later does not come.
  `Color(.systemGroupedBackground)` and friends do not appear in this app.
- **The signature interaction and the reward are the MVP, not polish.** A screen that works
  but does not move the way DESIGN.md says is not done.
- **The product is not the pitch.** No "no ads", "no timer", "nothing to buy" anywhere in the
  UI except the paywall's promise line. No text explaining the controls; teach by affordance.
- **Build against the iOS 26 SDK.** App Store Connect rejects anything older. Deployment
  target stays iOS 17 — SDK and deployment target are independent. Newer APIs go behind
  `if #available`.
- **Standard components for the chrome.** Tab bar, navigation, toolbars, sheets, toggles,
  pickers and buttons are the system's (`.brandProminent()` for the primary action), so the
  iOS 26 SDK gives them Liquid Glass. The content — boards, cards, art — is drawn by you.
- **No frozen font sizes.** `.font(.system(size:))` ignores Dynamic Type and the compliance
  gate fails on it. Use a text style, `brandFont`, or `brandDisplay(size:)` for display sizes.
- **Looping motion through FactoryKit** (`ambientFloat`, `breathing`, `confetti`,
  `brandBackground(drift:)`), or check `Motion.isStill` in your own — so captures settle.
- **No third-party dependencies.** SwiftUI, SwiftData, StoreKit 2, AVFoundation and
  FactoryKit only. Decided and reasoned in `CLAUDE.md`; if an effect is genuinely missing,
  it goes into FactoryKit on a first-party engine, not into the app on a package.
- **No placeholder text anywhere.** No `TBD`, no lorem ipsum, no `example.com`. That includes
  the kit's defaults: pass `OnboardingView(nextTitle:finishTitle:)` and
  `PaywallView(subhead:cta:)` so the app's first and last screens are in its own voice rather
  than "Continue".

## Steps

1. **Scaffold.** `tools/new-app.sh <slug> "<Display Name>"` copies the template into
   `apps/<slug>/ios`, renames the target and bundle id, and generates the project.
   The `.xcodeproj` is generated and gitignored — never commit it, and run
   `xcodegen generate` in `apps/<slug>/ios` if it is missing.

2. **Brand, icon, art.**
   - Replace `App/AppBrand.swift` with DESIGN.md's Tokens block.
   - Copy `design/icon-1024.png` over `App/Assets.xcassets/AppIcon.appiconset/icon-1024.png`
     (render it first with `node tools/icon.mjs … --svg apps/<slug>/design/icon.svg` if the
     PNG is missing). Never the glyph form of icon.mjs.
   - For each `design/art/<name>.svg`:
     `node tools/design/art.mjs apps/<slug>/design/art/<name>.svg apps/<slug>/ios/App/Assets.xcassets/<Name>.imageset --width <points>`.

3. **Identity.** Fill `App/AppInfo.swift` from the spec and DESIGN.md's Voice: name, product
   ids as its Monetization section says (`<bundle>.pro.weekly` and `.pro.yearly` for a
   subscription, `<bundle>.unlock` for a one-time unlock), onboarding pages with art
   (`OnboardingPage(title:subtitle:art:)`, DESIGN.md's lines), the paywall headline, bullets
   and promise, and the support and privacy URLs
   (`https://starhiveconcept.com/<slug>-privacy-policy-terms/` and the same with `#support`).
   Update `App/Products.storekit` so its product ids match exactly — a mismatch means the
   paywall shows nothing in the real build. It is also what App Store Connect's products are
   created from (`tools/asc/iap.mjs` in app-submit), so its text must fit Apple's limits:
   display name 2–30 characters; description at most **45** for a one-time unlock
   (`NonConsumable`) and 55 for a subscription; reference name 64. A free-trial introductory
   offer is the only kind automated. Check with `node tools/asc/products.mjs <slug>`.

4. **Build early.** `tools/sim.sh build apps/<slug>/ios <Target>`. Fix every error before
   writing a feature. A build break found now costs a minute; found after three screens it
   costs an hour.

5. **The core screen first, and its signature interaction.** The screen in `mock-1-play`,
   with the interaction exactly as DESIGN.md's beat-by-beat describes: the springs, the
   haptic at each beat, the tone, the settle, the first-time teaching. Then **the reward** from
   `mock-2-win`, with its tiers, count-up, confetti, haptic and line from the praise pool.
   Push. Only then the other screens from SPEC.md's MVP section. One file per screen once a
   screen passes ~150 lines. SwiftData or `@AppStorage` for persistence. FactoryKit's `Store`
   and `PaywallView` (with `hero:`) for the Pro gate. Network only if the spec names an API.
   Every string the user reads comes from DESIGN.md's Voice; pools are arrays picked at
   random, never the same line twice running.

   Add launch flags to `App/LaunchOptions.swift` for anything the tooling needs to reach
   deterministically — at minimum `-onboarded`, `-sampleData`, `-reset`, `-pro`,
   `-fakeProducts`, `-screen <name>`, a flag that lands on the win (`-won`, or `-screen win`),
   and **`-demo <moment>`**, which makes the app perform its signature interaction (and, as a
   second moment, reach its win) by itself shortly after launch, since nothing on a runner can
   touch the screen. `-fakeProducts` is not optional: a scheme's StoreKit configuration is
   never honoured by a `simctl launch`, so without it the paywall is unscreenshotable and shows
   a disabled button.

6. **Look at every screen, next to its mock.** Boot with `tools/sim.sh boot`, then for each
   screen `tools/sim.sh run … <flags> -stillFrames` and `tools/sim.sh shot … out.png`, and
   **Read the PNG next to the mock it implements.** List every way the build is flatter,
   grayer or more cramped than the mock, and fix them. Check dark mode and large text too:
   `tools/sim.sh ui dark` and `tools/sim.sh ui light accessibility-extra-extra-extra-large`.
   For motion, launch with `-demo <moment>` (no `-stillFrames`), then
   `tools/sim.sh frames "$RUNNER_TEMP/f" 8 0.15` and
   `node tools/qa/filmstrip.mjs "$RUNNER_TEMP/strip.png" "$RUNNER_TEMP"/f/frame-*.png` — Read
   the strip: if nothing changes between frames, nothing moves.

7. **Write `apps/<slug>/qa.json`** — `scheme`, `bundleId`, the `screens` to verify (each with a
   `name`, the launch `args` that reach it, and a `note`), and the `moments` the critic films
   (each with `name`, `args` including `-demo <moment>`, and optionally `delay`, `frames`,
   `interval`, `note`) — at least the signature interaction and the win. `app-verify` and
   `app-shots` drive the screens; `app-polish` films the moments. Include the win as a
   screen: it is usually the best screenshot the app has.

8. **Write `apps/<slug>/privacy.json`** — what the app actually stores, any network call it
   makes, and every required-reason API it touches (`@AppStorage` is
   `NSPrivacyAccessedAPICategoryUserDefaults`, reason `CA92.1`). Then
   `node tools/privacy/sync.mjs <slug>` to generate the manifest and the App Store answers.
   Declaring an API you do not use is as wrong as omitting one you do.

9. **Verify.** `.github/scripts/verify-app.sh <slug>` builds, launches every screen in
   qa.json, proves each rendered and that nothing crashed. It must pass. Then
   `node tools/design/tells.mjs <slug>` must report no FAIL — its list is TASTE.md's slop
   tells that can be seen in code.

10. **Write the listing, while the app is fresh in mind.** Everything here comes straight
    out of SPEC.md's Store section, and writing it now is what lets the screenshot,
    compliance and page stages run afterwards without another agent.

    `apps/<slug>/store/screenshots.json` — `background` (a CSS gradient from the brand's
    palette, not a generic navy), `textColor`, `accent`, `font` (the brand's display face:
    `serif`, `rounded`, `monospaced` or `default` — the same face `AppBrand`'s `BrandType`
    sets, so the frame is in the app's own type rather than SF Pro over a screenshot that
    is not), and one entry per screen in qa.json
    with a `title` under 40 characters and an optional `subtitle`. Order them by beauty: the
    first screenshot is the one that makes someone want the app — usually the win or the
    core screen mid-interaction. Titles state a benefit, not a feature; at least one is the
    Wedge said plainly. This is the store, so the pitch belongs here.

    `apps/<slug>/store/metadata/en-US/` — `name.txt` (30), `subtitle.txt` (30),
    `keywords.txt` (100, comma-separated, **no spaces after the commas**),
    `promotional_text.txt` (170), `description.txt` (4000), `release_notes.txt`,
    `support_url.txt`, `privacy_url.txt`. Check every one with `wc -c`.

    Two rules that cost nothing now and a rejection later: do not repeat a word from the
    name or subtitle in `keywords.txt`, because Apple indexes all three together and a
    repeat spends the characters twice; and every claim in `description.txt` must be true
    of the binary you just built — if it says "no ads", grep for an ad SDK before writing it.

    `apps/<slug>/store/release.json` — what `app-release` sets in App Store Connect, from
    SPEC.md's Store section: `primaryCategory` and `secondaryCategory` as App Store Connect
    ids (`UTILITIES`, `PRODUCTIVITY`, `HEALTH_AND_FITNESS`…); a game is `GAMES` with
    `primarySubcategoryOne` (and optionally `Two`) such as `GAMES_PUZZLE`, `GAMES_WORD`,
    `GAMES_BOARD`, `GAMES_TRIVIA`. `contentRights` is `DOES_NOT_USE_THIRD_PARTY_CONTENT`
    unless the app shows content someone else owns (a trivia API, a font you did not draw).
    `ageRating` lists only the answers that are not "none" — e.g. `"unrestrictedWebAccess":
    true` for an app with a web view. `price` is `"0"`. `apps/tallies/store/release.json` is
    the shape.

11. **Update `apps/<slug>/STATUS.md`** — `stage: built`, what works, what is stubbed, what
    could not be checked without hardware. Commit.

## Done means

`verify-app.sh` passes, `tells.mjs` reports no FAIL, every screen in the spec exists and
renders in the brand, the signature interaction and the reward behave as DESIGN.md describes
and qa.json's moments show them moving, the paywall shows both products with
`-fakeProducts`, there is no placeholder text, `factoryReviewPrompt` is still wired, and the
listing files in step 10 exist and are inside their limits. Then `app-polish` has a fresh
critic score it against TASTE.md, and polishes until it passes.

## What you cannot do here, and must not pretend to

- **A real purchase.** No runner can complete one. Say so in STATUS.md.
- **Feel haptics or hear sounds.** Wire them exactly as DESIGN.md says; the owner's TestFlight
  pass on a phone is where they are felt.
- **Notifications firing, the share sheet.** Both need hardware.
- **`/ios-qa` and `/ios-design-review`.** Both need a physical iPhone over USB. The screenshot
  and filmstrip passes in step 6 replace them.
