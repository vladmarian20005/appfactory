stage: shelved (demo run, owner chose not to ship, 2026-09-08)
date: 2026-09-08
built:
  - Xcode project factory/apps/plainfood/ios (target Plainfood, bundle com.factory.plainfood), builds and runs on the iPhone 15 Pro Max simulator
  - Today (ring, macros, meals, edit/delete), Add food (Open Food Facts search, barcode via VisionKit on device with manual code fallback, manual entry, recent foods), Trends (Pro, 7/30 day charts, average, streak), Goals with presets, Settings, paywall with the free-forever promise
  - Launch flags for tooling: -onboarded -sampleData -screen <add|scan|trends|goals|paywall|settings> -query "<text>" -pro -fakeProducts
  - Store: five composed 6.7" screenshots, fastlane metadata (limits checked), privacy and support pages, landing page in sites/plainfood
  - Content: five video scripts, ten X posts, two Reddit posts, Product Hunt listing, launch email, press blurb, schedule
not verified:
  - Real purchases: StoreKit config only applies when Xcode launches the app; run the Plainfood scheme from Xcode to test the sandbox purchase
  - Barcode camera: simulator has no camera; manual code lookup tested (Nutella 3017624010701)
blocked:
  - Upload to TestFlight and submission: needs Apple Developer Program, App Store Connect API key (ASC_KEY_ID, ASC_ISSUER_ID, ASC_KEY_PATH) and TEAM_ID
  - sites/plainfood hosting: repo is private, so GitHub Pages needs a public repo or Vercel
  - Support email: replace SUPPORT_EMAIL_TBD in sites/plainfood/support/index.html
next: none. Kept as the reference app for the template, tooling and skills.
