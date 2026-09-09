---
name: new-app
description: Scaffold an iOS app from the template and implement the screens from SPEC.md, building and checking it on the simulator. Use for "scaffold", "new app", "start building", "build <slug>".
---

# /new-app <slug> "<Display Name>"

Requires `apps/<slug>/SPEC.md`. Produces an app that builds, runs, and renders every screen.

You are most likely running on a `macos-26` GitHub runner with no GUI, no physical device and
no Xcode window. Everything below works there. Nothing below needs a human.

## Rules that are not negotiable

- **Commit after each screen works, never once at the end.** If the run dies mid-task the
  runner is destroyed and uncommitted work is gone with it.
- **Build against the iOS 26 SDK.** App Store Connect rejects anything older. Deployment
  target stays iOS 17 — SDK and deployment target are independent.
- **Use standard SwiftUI components.** Building against the iOS 26 SDK applies Liquid Glass
  to native controls automatically; a hand-rolled control opts out of it and looks wrong next
  to the rest of the system.
- **No frozen font sizes.** `.font(.system(size:))` ignores Dynamic Type and the compliance
  gate fails on it. Use a text style, or `.scaledFont(size:)` from FactoryKit when the design
  genuinely needs a display size.
- **No third-party dependencies.** SwiftUI, SwiftData, StoreKit 2 and FactoryKit only.
- **No placeholder text anywhere.** No `TBD`, no lorem ipsum, no `example.com`.

## Steps

1. **Scaffold.** `tools/new-app.sh <slug> "<Display Name>"` copies the template into
   `apps/<slug>/ios`, renames the target and bundle id, and generates the project.
   The `.xcodeproj` is generated and gitignored — never commit it, and run
   `xcodegen generate` in `apps/<slug>/ios` if it is missing.

2. **Icon.** `node tools/icon.mjs apps/<slug>/ios/App/Assets.xcassets/AppIcon.appiconset/icon-1024.png "<glyph>" "<css gradient>"`.
   One or two characters that read at 60px. Pick a gradient that is not the template's green.

3. **Identity.** Fill `App/AppInfo.swift` from the spec: name, product ids
   (`<bundle>.pro.weekly` and `.pro.yearly`), three onboarding pages drawn from the Promise
   and the Wedge, the paywall headline and bullets, and the support and privacy URLs
   (`https://starhiveconcept.com/<slug>-privacy-policy-terms/` and the same with `#support`).
   Update `App/Products.storekit` so its product ids match exactly — a mismatch means the
   paywall shows nothing in the real build.

4. **Build early.** `tools/sim.sh build apps/<slug>/ios <Target>`. Fix every error before
   writing a feature. A build break found now costs a minute; found after three screens it
   costs an hour.

5. **Implement the screens** from SPEC.md's MVP section. One file per screen once a screen
   passes ~150 lines. SwiftData or `@AppStorage` for persistence. Keep FactoryKit's `Store`
   and `PaywallView` for the Pro gate. Network only if the spec names an API.

   Add launch flags to `App/LaunchOptions.swift` for anything the tooling needs to reach a
   screen deterministically — at minimum `-onboarded`, `-sampleData`, `-reset`, `-pro`,
   `-fakeProducts`, and `-screen <name>`. `-fakeProducts` is not optional: a scheme's
   StoreKit configuration is never honoured by a `simctl launch`, so without it the paywall
   is unscreenshotable and shows a disabled button.

6. **Look at every screen.** Boot with `tools/sim.sh boot`, then for each screen
   `tools/sim.sh run … <flags>` and `tools/sim.sh shot … out.png`, and **Read the PNG**.
   A screen that compiles and renders wrong is exactly what this catches. Check dark mode and
   large text too: `tools/sim.sh ui dark` and
   `tools/sim.sh ui light accessibility-extra-extra-extra-large`.

7. **Write `apps/<slug>/qa.json`** — `scheme`, `bundleId`, and the screens to verify, each
   with a `name`, the launch `args` that reach it, and a `note`. This is what `app-verify`
   and `app-shots` drive, so every screen that matters to the listing belongs in it.

8. **Write `apps/<slug>/privacy.json`** — what the app actually stores, any network call it
   makes, and every required-reason API it touches (`@AppStorage` is
   `NSPrivacyAccessedAPICategoryUserDefaults`, reason `CA92.1`). Then
   `node tools/privacy/sync.mjs <slug>` to generate the manifest and the App Store answers.
   Declaring an API you do not use is as wrong as omitting one you do.

9. **Verify.** `.github/scripts/verify-app.sh <slug>` builds, launches every screen in
   qa.json, proves each rendered and that nothing crashed. It must pass.

10. **Update `apps/<slug>/STATUS.md`** — `stage: built`, what works, what is stubbed, what
    could not be checked without hardware. Commit.

## Done means

`verify-app.sh` passes, every screen in the spec exists and renders, the paywall shows both
products with `-fakeProducts`, there is no placeholder text, and `factoryReviewPrompt` is
still wired. Then `/ship <slug>` takes it to the App Store.

## What you cannot do here, and must not pretend to

- **A real purchase.** No runner can complete one. Say so in STATUS.md.
- **Haptics, notifications firing, the share sheet.** All need hardware.
- **`/ios-qa` and `/ios-design-review`.** Both need a physical iPhone over USB. The screenshot
  pass in step 6 replaces them.
