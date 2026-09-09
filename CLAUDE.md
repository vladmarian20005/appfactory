# appfactory · the hands

This repo builds and ships iOS apps. It runs almost entirely on GitHub Actions;
a laptop is the fallback, not the default.

The brain lives elsewhere: **[appmonkey](https://github.com/vladmarian20005/appmonkey)**
(private) runs the daily scout that decides *what* to build. This repo takes a spec and
turns it into an app in App Review.

## Layout

```
FactoryKit/          Swift package every app depends on: Store, paywall, onboarding,
                     settings, theme, accessibility. Shared code goes here, never copied
                     into an app.
template/            XcodeGen project the scaffolder copies for a new app.
apps/<slug>/         SPEC.md, PLAN.md, STATUS.md, state.json, ios/, store/, content/
tools/               new-app.sh, sim.sh, icon.sh, screenshots/, pages/, fastlane/
.github/workflows/   app-*.yml — one workflow per factory stage
.github/actions/     mac-setup, asc-key, factory-state, report
```

## Rules

- **Everything runs in CI.** Any tool that only works on a laptop is a bug. No dependency
  on binaries outside this repo and the runner image.
- **`*.xcodeproj` is generated, never committed.** Every macOS job runs `xcodegen generate`
  before it builds or archives.
- **Build with the iOS 26 SDK.** App Store Connect has rejected anything older since
  28 April 2026. Deployment target stays iOS 17 — SDK and deployment target are independent.
- **Use standard components.** Building against the iOS 26 SDK applies Liquid Glass to
  native controls automatically; a re-implemented control opts out of it and looks wrong.
- **Never commit secrets.** This repo is public. Keys live in GitHub Actions secrets and,
  locally, in `tools/fastlane/.env` (gitignored). See `.gitignore` before adding a file type.
- **Apple compliance is a gate, not a review step.** `app-compliance.yml` fails the build on
  a missing privacy manifest, an unreachable privacy URL, a paywall without auto-renew
  disclosure, or placeholder text. Fix the app, not the gate.
- **`state.json` is the handoff.** Each stage asserts the previous one passed and its commit
  is still an ancestor of HEAD. `STATUS.md` is prose for humans; `state.json` is for the
  pipeline.

## The week

| Day | Workflow | Owner's part |
| --- | -------- | ------------ |
| Mon | `app-plan` → `app-build` | none (autonomy rule: no reply by noon = build candidate #1) |
| Tue | `app-verify` ⇄ `app-fix` | none |
| Wed | `app-shots` → `app-compliance` → `app-pages` | none |
| Thu | `app-submit` | TestFlight pass on a phone, then `/approve submit` |
| Fri | `app-release`, `app-content` | none |

## Revenue numbers

Every revenue figure the factory quotes is **modeled**, not reported sales. Say "modeled"
whenever one appears in a spec, a report or a page.
