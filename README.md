# appfactory

A pipeline that builds and ships one iOS app a week, on cloud runners, with one human
decision per app.

Give it a spec. It writes a design direction — the idea, the look, the signature
interaction, the reward, the voice, an icon and mocks — builds a SwiftUI app to it from a shared
kit on a macOS runner, fixes its own compile and runtime failures, has a separate critic judge
it against a taste bar and polishes until it passes, captures and composes App Store screenshots,
writes the store metadata, generates and publishes a privacy policy, checks the result
against Apple's review guidelines, uploads to TestFlight and submits for review.

The one thing it will not do on its own is press submit.

## How it works

Every stage is a GitHub Actions workflow on an ephemeral runner. Git is the database: a
stage checks out the app's branch, asserts the previous stage passed, does one thing,
commits, and comments on the app's issue. The chain advances itself with `workflow_run`.

```
app-plan → app-build → app-verify ⇄ app-fix → app-polish ⇄ (critic, polish) → app-aso
         → app-shots → app-pages → app-compliance → [ /approve submit ] → app-submit
         → app-release → app-content
```

Xcode work runs on `macos-26`; everything else runs on Linux.

## What's in here

| | |
| --- | --- |
| `TASTE.md` | The bar: what every app needs so people love it rather than tolerate it, the slop tells that fail it, and the rubric the critic scores. |
| `FactoryKit/` | The Swift package every app depends on — brand theming, motion, confetti, synthesized tones, share images, StoreKit 2 paywall, onboarding, settings, accessibility helpers. No third-party dependencies. |
| `template/` | The XcodeGen project a new app is scaffolded from. |
| `apps/<slug>/` | One directory per app: the spec, the plan, the Xcode sources, store assets, launch content. |
| `tools/` | The scaffolder, the simulator driver, the design tools (mocks, drawn icons and art, contrast, slop tells, filmstrips), the screenshot composer, the page generator, the fastlane lanes. |

## The taste gate

`app-polish.yml` refuses to let a working app through when it is joyless. A critic — a
different agent from the one that built it — reads every screen in light and dark, at the
largest text size, and filmstrips of the app's signature interaction and its win, then scores
it against `TASTE.md`. Below the bar, a polish agent works through the critique and the
critic looks again, twice at most before a human decides. `tools/design/tells.mjs` backs the
verdict: a system-gray canvas, a win in a sheet, or the store pitch printed in the UI fails it
whatever the critic thinks.

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
