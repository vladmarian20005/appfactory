stage: planned
date: 2026-09-11
spec: SPEC.md · plan: appmonkey `plans/color-sort/PLAN.md` (private) · evidence: appmonkey `plans/color-sort/evidence.json`
next: app-build

## Where it stands

Planned from [issue #3](https://github.com/vladmarian20005/appfactory/issues/3) by the build-request
procedure. Evidence gathered by `plan-evidence` on 2026-09-11 — the niche sized, the top five apps
torn down, 100 reviews sampled from each. All five feeds returned data; there is no app in this
evidence without reviews.

Verdict: **go**. The niche is $13M/mo modeled across 49 apps, the leader takes 26%, and 55–83% of
sampled reviews are negative across all five top apps. The wedge is a solvability guarantee, no ads
and no currency.

Nothing has been built. `apps/color-sort/ios/` does not exist yet — that is `app-build`'s job.

## Next

`app-build` scaffolds from `template/` and implements the three screens in SPEC.md, then
`app-verify` ⇄ `app-fix`, then aso → shots → pages → compliance.

## Blocked on the owner

Nothing yet. Before the App Store Connect record exists, two things need a human:

1. **Search the App Store for `Tidepour`.** The planning sandbox has no route to Apple, so the name
   was checked only against the five apps in the evidence. Alternates: `Hueflask`, `Pourline`.
2. **Create the app record and the one non-consumable IAP** (`com.starhiveconcept.colorsort.unlock`,
   $4.99). Apple's API refuses `CREATE` on `apps`.

Then the TestFlight pass on a real phone — haptics, share sheet, a real sandbox purchase — none of
which CI can check.
