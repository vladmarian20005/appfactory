---
name: new-app
description: Scaffold an iOS app from template, implement the three screens from SPEC.md, build and QA on the simulator. Use for "scaffold", "new app", "start building".
---

# /new-app <slug> "<Display Name>" [bundle-id]

Requires `apps/<slug>/SPEC.md` (from `/pick`). Everything runs locally; Xcode 16 and XcodeGen are installed.

1. Scaffold: `tools/new-app.sh <slug> "<Display Name>"`. This copies the template into `apps/<slug>/ios`, renames the target and bundle id, and generates the Xcode project.
2. Icon: `tools/icon.sh apps/<slug>/ios/App/Assets.xcassets/AppIcon.appiconset/icon-1024.png "<one glyph>" "<css gradient>"`. Pick a gradient that is not green (the template's) and a glyph that reads at 60px.
3. Fill `App/AppInfo.swift` from the spec: name, support and privacy URLs (`https://vladmarian20005.github.io/appmonkey/<slug>/…`), product ids, onboarding pages (three, from Promise and Wedge), paywall headline and bullets. Update the product ids in `App/Products.storekit` to match.
4. Build: `tools/sim.sh build apps/<slug>/ios <Target>`. Fix errors before going on.
5. Implement the three screens in `App/RootView.swift` (split into files when a screen exceeds ~150 lines). Rules: SwiftUI only, SwiftData or `@AppStorage` for persistence, no networking unless the spec lists an API and the owner supplied the key, keep the `Store` and `PaywallView` pattern for the Pro gate, every string in English and free of placeholders.
6. Run and look: `tools/sim.sh run …` then `tools/sim.sh shot … out.png` and Read the PNG. Do this for every screen. Then `/ios-qa` on the project, `/ios-design-review`, and `/ios-fix` for anything found.
7. Done means: cold start with no crash, every screen in the spec works, the paywall shows both products from the local StoreKit file and completes a sandbox purchase, no placeholder text, `factoryReviewPrompt` stays wired.
8. Update STATUS.md (`stage: built`, what works, what is stubbed) and commit with a message that names the app.
