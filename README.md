# appfactory

A pipeline that builds and ships one iOS app a week, on cloud runners, with one human
decision per app.

Give it a spec. It scaffolds a SwiftUI app from a shared kit, builds it on a macOS runner,
fixes its own compile and runtime failures, captures and composes App Store screenshots,
writes the store metadata, generates and publishes a privacy policy, checks the result
against Apple's review guidelines, uploads to TestFlight and submits for review.

The one thing it will not do on its own is press submit.

## How it works

Every stage is a GitHub Actions workflow on an ephemeral runner. Git is the database: a
stage checks out the app's branch, asserts the previous stage passed, does one thing,
commits, and comments on the app's issue. The chain advances itself with `workflow_run`.

```
app-plan → app-build → app-verify ⇄ app-fix → app-shots → app-compliance
         → app-pages → [ /approve submit ] → app-submit → app-release → app-content
```

Xcode work runs on `macos-26`; everything else runs on Linux.

## What's in here

| | |
| --- | --- |
| `FactoryKit/` | The Swift package every app depends on — StoreKit 2 paywall, onboarding, settings, theme, accessibility helpers. No third-party dependencies. |
| `template/` | The XcodeGen project a new app is scaffolded from. |
| `apps/<slug>/` | One directory per app: the spec, the plan, the Xcode sources, store assets, launch content. |
| `tools/` | The scaffolder, the simulator driver, the screenshot composer, the page generator, the fastlane lanes. |

## The compliance gate

`app-compliance.yml` refuses to let an app reach App Review without:

- a valid `PrivacyInfo.xcprivacy` declaring every required-reason API it touches
- a privacy policy and support page that return 200
- a paywall showing price, duration, auto-renew disclosure, Restore, Terms and Privacy
- store metadata inside Apple's character limits
- screenshots at 1320×2868 with no alpha channel
- no placeholder text anywhere in the app or the listing
- a distinctness check against every other app in the portfolio (guideline 4.3)

## Running it locally

Needs Xcode 26, [XcodeGen](https://github.com/yonaskolb/XcodeGen) and Node 22.

```sh
tools/new-app.sh <slug> "<Display Name>"     # scaffold from template/
tools/sim.sh build apps/<slug>/ios <Target>  # build for the simulator
tools/sim.sh run   apps/<slug>/ios <Target>  # install and launch
```

App Store Connect credentials go in `tools/fastlane/.env` (gitignored) via
`tools/setup-keys.sh`. They are never committed; CI reads them from Actions secrets.

## License

MIT. The apps built with it are their authors'.
