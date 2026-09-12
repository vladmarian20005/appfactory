# Handoff · the taste work · 2026-09-11

For the next session. Read this, then `TASTE.md` and `CLAUDE.md`, before touching anything.

## Why this work exists

The owner tested the first two apps through the factory, **Quizday** (daily trivia) and
**Tidepour** (`color-sort`, the pour game), and called them slop: "functional, but way too
basic, no emotion, too plain, too boring… all apps need to have personality, not be boring and
sad." The goal: the factory makes **genuinely impressive apps — great UX, great UI**.

What made them bland, found in the code and pipeline:

- The spec is a market analysis, and its voice leaked into the UI ("No timer, no lives, no
  coins. Nothing here expires and nothing here runs out.").
- FactoryKit's theme was `systemGroupedBackground` + white cards; the template started there.
- The build prompt said "a verified app with no dark-mode check beats a beautiful one" and
  "every screen, minimal but real".
- The capture tooling waits for the screen to stop moving, so agents removed animation ("a
  lift rather than a bounce: the capture tooling waits for the screen to stop moving").
- `tools/icon.mjs` could only draw a glyph on a gradient ("10" on purple).
- No stage judged quality: verify only proves screens render.

## What this session built

Three commits on `main`: `76b2d49` (FactoryKit), `77d4cbb` (tooling), `842859e` (taste bar,
stages, workflows, docs).

| Piece | Where | What it does |
| --- | --- | --- |
| The bar | `TASTE.md` | Seven things every app has (idea, look, signature interaction, reward, voice, life, share) + drawn icon; 12 slop tells; the 1–5 rubric and pass rule |
| Direction stage | `.claude/skills/direct/SKILL.md`; first agent step of `app-build.yml` | Writes `DESIGN.md` (idea, palette + contrast, interaction and reward beat by beat, voice pools, `AppBrand` tokens), `design/icon.svg`, `design/art/*.svg`, three HTML mocks it renders and revises; looks at the leaders' store screenshots |
| Build | `.claude/skills/new-app/SKILL.md` (rewritten) | Brand from the first line; signature interaction + reward are MVP; the pitch stays in the store; qa.json `moments` + a `-demo <moment>` launch flag |
| Taste gate | `.github/workflows/app-polish.yml`, `.claude/skills/critique/`, `.claude/skills/polish/` | Fresh critic reads light/dark/AX captures + filmstrips + code → `CRITIQUE.md`, `design-score.json`; fail → polish agent → verify → next run re-judges; 2 passes then a human. Backed by `tells.mjs --strict`. Pass → `app-aso` |
| Chain | `app-build` and `app-fix` now dispatch `app-polish` (was `app-aso`); `app-verify` stands down while it runs | |
| FactoryKit | `Brand.swift`, `Motion.swift`, `Celebration.swift`, `Tones.swift`, `ShareImage.swift`, `Haptics.swift`, onboarding + paywall restyled | Brand theming (palette, display type, solid/wash/glow/mesh canvas), springs, `popIn`, `ambientFloat`, `breathing`, `shake`, `CountUp`, `confetti`, synthesized tones + `SoundsToggle`, image share cards, onboarding/paywall with custom art. Old APIs unchanged |
| Capture determinism | `Motion.isStill`, `verify-app.sh` appends `-stillFrames` | Looping motion pauses and confetti freezes at its peak under the flag, so apps can move and captures still settle |
| Tools | `tools/design/{render,art,icon via tools/icon.mjs --svg,contrast,leaders,tells}.mjs`, `tools/qa/filmstrip.mjs`, `tools/sim.sh frames`, `.github/scripts/design-captures.sh` | Mocks (WebKit for SF Rounded/New York), SVG → image sets, contrast checks, competitor screenshots, slop-tell scan, motion filmstrips, dark/AX/moment captures |
| Template | `template/App/AppBrand.swift`, `TemplateApp.swift`, `RootView.swift` | New apps start on brand APIs, not gray |

**Verified locally** (Xcode 16.3, iOS 18.4 simulator): FactoryKit typechecks clean; Quizday,
Tidepour and the template build against it unchanged; a demo app showed the kit on the
simulator; `verify-app.sh color-sort` passes with `-stillFrames`; `design-captures.sh` ran end
to end including a filmstrip; `tells.mjs` finds 16 hard tells in Tidepour and 19 in Quizday.

**Not verified before this handoff:** anything in CI except what the "Runs" section below
says. The iOS 26-only branch of `brandProminent()` (`.buttonStyle(.glassProminent)`) could not
compile locally; the API name is confirmed in Apple's docs.

## Runs started at the end of this session

The owner asked: push, run the pipeline, and get both apps into TestFlight.

The plan was: push → push-triggered `app-verify` proves the kit on Xcode 26 → `app-polish`
for `color-sort` and `quizday` (chain on) → direction, critique, up to two polish passes →
`app-aso` → `app-shots` → `app-pages` → `app-compliance` → `app-register` → **`app-submit`
by hand** (confirm `SUBMIT`). The last step is manual on purpose: `app-await-record` only
auto-starts `app-submit` for apps never uploaded, and both apps already have a `submit` stage.
`app-submit` uploads to TestFlight only; review submission is `app-release`, which nobody has
run for either app.

### What happened (UTC, 11–12 September)

| Time | Event |
| --- | --- |
| 20:07 | Push of the three commits. `app-verify` (Xcode 26): quizday, color-sort, tallies all **pass** — the kit, including the iOS 26 glass button, compiles and renders in CI. |
| 20:08 | `app-compliance` **fails all three apps**: "the listing says there is no analytics, but an analytics SDK is linked" — the gate's grep matched `ambientFloat(amplitude:)` in FactoryKit. Fixed in `4f38e1c` (renamed to `distance:`); compliance passes locally for all three. The chain re-runs compliance on the fixed code. `app-compliance` re-dispatched for tallies to clear its false fail. |
| 20:19 | `app-polish` dispatched: color-sort run `34643638691`, quizday run `34643641266`. |
| 20:35–20:44 | **Quizday direction lands** (`57b9af6`, `9d2a2ea`): "a one-sheet morning newspaper that prints itself fresh every day" — ink-press answers, a red stamp on every answer, pencilled corrections instead of red, a front page that prints itself with five tiers, a night-editor voice with ten praise and eight near-miss lines, New York throughout, six drawn SVGs, a stamped-newsprint icon. Its three mocks are genuinely good. One flaw: its tokens' `AppBrand.dateline(_:)` returns `.system(size:)`, a frozen size neither the compliance grep nor `tells.mjs` catches. |
| 20:53 | **Quizday critique: fail** (idea 1, look 2, signature 2, reward 1, voice 2, craft 3, first minute 2). Harsh, specific, evidence by file:line and screenshot; caught unseeded sample data and AX layout breaks. The critic is working as intended. Polish pass 1 started. |
| 20:58 | **Color-sort critique: fail** (1/2/1/1/2/3/2). But its direction step produced mocks, an icon and art and **no DESIGN.md** — most likely out of turns at 90. The critic flagged `no-direction`; the polish agent has to write DESIGN.md itself. Fixed for future apps in `5b36aff`: the skill writes and pushes DESIGN.md before drawing, and the step gets 120 turns. Also `edfd23a`: app-polish's job timeout 240 → 330 minutes, so a long polish pass cannot be killed before it records itself. |
| 21:21 | Color-sort's polish agent writes the missing DESIGN.md first (as the polish skill says), from the direction agent's mocks: "a tide-pool apothecary at dusk… decanting one glow into another." Mocks: glowing vials standing in water, a tilted vial mid-pour, the hint as "the charted line", a low-sun win screen. |
| 21:22 | Compliance re-runs on a polish push: **ok for both** — the `amplitude` fix holds in CI. |
| ~21:45 | Color-sort's polish agent **fixes a real FactoryKit bug** (`500899f`): `.brand()` sets `.fontDesign(body)` at the root, which overrode `brandFont`'s display design — a New York or Rounded brand silently rendered SF Pro wherever `brandFont` was used. Fixed by restating `.fontDesign(display)` inside `BrandFont`/`BrandDisplay`. |
| 21:52 | Color-sort compliance **fails transiently**: its polish reordered qa.json and screenshots.json (the win is now screenshot 1, the paywall 6) and the composed store screenshots are stale until `app-shots` re-composes them, which the chain does before compliance. Expected to clear. |
| 21:53–21:56 | **Both polish passes end on their turn caps, not their clocks.** From the color-sort log: direction `error_max_turns` at 91 turns / 24 min, critique `success` at 53 turns / 4 min, polish `error_max_turns` at 181 turns / 55 min. Quizday's pass verified ok and dispatched its re-judge; color-sort's pass stopped mid-edit and left `TubeView.swift:169: cannot find 'ringStrength' in scope`, so verify failed and **app-fix** took it (as designed; it sends a repaired app back to app-polish). |
| 22:00 | `eb0cc54`: polish 180 → **400** turns, critique 45 → 80, build default 260 → **400**. Quizday's re-judge run (`34651740292`, still in runner setup, nothing recorded) cancelled and re-dispatched so its second and last polish pass gets 400 turns. |
| 22:26 | **Quizday passes the taste gate** — idea 5, look 4, signature 4, reward 4, voice 5, craft 4, first minute 4, no tells, after **one** polish pass. The build is the newspaper: grained newsprint under a lamp, the drawn press, ruled answer boxes that take ink under a red stamp, wrong answers pencilled out, a front page that prints itself at 112 pt with a brass ribbon, a designed dark mode, a share card. Chain continues: aso ok 22:32, shots next. |
| 22:07–22:33 | Color-sort's verify failed on **one blank capture** (`03-chart`, 1 distinct colour) — a screen that did not draw inside the capture's 30 s. `app-fix` reproduced it, found verify **green**, and hit its "Already fine" path, which dispatched nothing: the app stalled with `verify=fail` recorded and no run in flight. Fixed in `655b49d` — that path now records the green and dispatches app-polish, the same next hop as a real fix. Color-sort re-dispatched by hand. |
| 22:45 | Quizday's chain completes: shots, pages, compliance, register all ok on the polished code. Its store screenshots are the newspaper too, and the pitch is where it belongs — on the store frames, not in the app. |
| 22:50 | **Quizday uploaded to TestFlight**, build `202609112248` (`app-submit`, run `34655543910`). Review submission (`app-release`) was not run and is still the owner's call. |
| 22:47–22:57 | Color-sort's board screen renders as a **flat white window** in some runs (`03-chart` in one, `02-play` in the next) while its win, chart and onboarding screens render beautifully. Verify photographs the empty window after its 30 s settle window expires — which is also what a player would see. It is intermittent: two of four verify runs hit it, and the fix loop twice found verify green on re-run. Dealing is already off the main thread (`GameModel` line ~125 `Task.detached`), so the block is elsewhere — a long `@MainActor` solve on the hint/auto-play path is the next place to look. |

**Note for local work:** the apps no longer build on Xcode 16.3 (color-sort hits `ambiguous use of 'sin'` in `BoardView.swift`, which Xcode 26 accepts), and `tools/sim.sh build` only runs `xcodegen generate` when the `.xcodeproj` is missing, so a local project goes stale when an agent adds a file. Regenerate by hand before building locally; CI always regenerates.
| 23:16 | **Color-sort passes the taste gate** — idea 5, look 4, signature 4, reward 5, voice 4, craft 4, first minute 4, also after one polish pass. "A tide pool at dusk that happens to contain a sorting puzzle… recognisable from one crop and worth sending to a friend." |
| 23:31 | Its `app-shots` fails on the same blank-capture problem, two screens this time (`04-shore`, `07-first`), and the chain stalls. `6270a3f`: `sim.sh`'s settle window 30 s → **60 s**, since verify reinstalls before every screen and a cold first launch sometimes needs longer to draw. Re-dispatched. |
| 23:44 | Color-sort's chain completes clean: shots, pages, compliance, register all ok. |
| 23:48 | **Color-sort uploaded to TestFlight**, build `202609112345`. |

### Where it stands

Both apps cleared the gate on their first polish pass and are **on TestFlight**: Quizday
`202609112248`, Tidepour `202609112345`. Neither has been submitted for review — `app-release`
is still the owner's call, and the owner's device pass (haptics, sounds, a sandbox purchase,
the reminder firing) has not happened.

The pipeline now runs end to end unattended except for the three interventions above, each of
which is fixed in the repository: the analytics-word false positive, `app-fix`'s dead-end
"already fine" path, and the 30-second capture window. The turn caps were resized once from
the first runs' evidence.

## Decisions for the next session

### 1. UI framework and kits (the owner wants this decided next session)

The owner asked: "Are there better UI kits we can use instead?" Notes so far, to verify and
decide on:

- **Stay native SwiftUI.** The iOS 26 SDK gives system controls Liquid Glass for free; any kit
  that re-draws controls loses it. This is the baseline under every option below.
- **Generic component / "Liquid Glass" kits** (LiquidGlassKit, SwiftUI-Components, The Swift
  Kit…): likely a step backwards — re-implemented controls, and the look they give is the
  same one everyone using them gets. The problem was never missing components; it was
  direction, motion and craft.
- **Effect libraries, pure SwiftUI, MIT, no assets — the promising ones**, because an agent on
  a runner can use them without a design tool:
  - [Pow](https://github.com/EmergeTools/Pow) (Emerge Tools, MIT, v1.0.5): transitions and
    "change effects" that fire on value changes — shine, spray, jump, shake, glow.
  - [Vortex](https://github.com/twostraws/Vortex) (Paul Hudson): particle systems —
    confetti, fireworks, fire, rain, smoke, magic, custom.
  - [Inferno](https://github.com/twostraws/Inferno) (Paul Hudson): Metal shaders for SwiftUI
    — water ripples, shimmer, noise, emboss, gradients.
- **First-party engines, no dependency at all:** SpriteKit via `SpriteView` for games
  (physics, emitters configured in code, actions) — the pour game is a natural fit; SwiftUI
  shader effects (`.colorEffect`, `.distortionEffect`, `.layerEffect`, iOS 17) for liquid and
  glow; Core Haptics (AHAP patterns) for richer feel; TipKit for teaching by affordance.
- **Asset-driven animation** (Rive, Lottie): the best results in the industry, but they need
  assets authored in a GUI editor, which a runner cannot do. Park unless there is a source of
  licensed assets.
- **Cross-platform (Flutter, React Native):** no. Loses native Liquid Glass and doubles the CI.

Criteria to decide by: can an agent author with it on a runner (no GUI editor, no missing
assets); iOS 17 deployment target; license; maintenance; binary size; privacy manifest
(third-party packages that touch required-reason APIs must ship their own). Adopting any
package means changing the "no third-party dependencies" rule in `CLAUDE.md` and
`.claude/skills/new-app/SKILL.md` (and `TASTE.md`'s vocabulary table), and deciding whether
it is an app dependency or wrapped by FactoryKit (FactoryKit wrapping keeps one API for every
app and one place to pin versions).

### 2. Make the cloud pipeline functional

The new stages were written and tested locally, but their first CI runs are the ones above.
Known risks, in the order they would bite:

1. `claude-code-action` runs two or three times in one job now (direct + build; direct +
   critique + polish). Auth between invocations is untested; `git-auth.sh` runs after each.
2. Playwright WebKit on `macos-26`: `npm run browser` now installs Chromium **and** WebKit;
   the cache key did not change, so the first run downloads it.
3. `tools/design/leaders.mjs` needs `itunes.apple.com` from the runner.
4. The Claude subscription's usage limits: one app is now direction (≤90 turns) + build
   (≤260) + critique (≤45) up to three times + polish (≤180) up to twice. Two apps at once
   doubles that.
5. Existing apps have no `moments` or `-demo` flag; the polish skill tells the agent to add
   them. Watch whether it does.
6. The critic's leniency: read the first `CRITIQUE.md`s and compare with the captures. If it
   passes something that still looks like the template, tighten `critique/SKILL.md` and
   `tells.mjs`.
7. `appmonkey` does not know about the new stages: `docs/BUILD-REQUEST.md` promises "about an
   hour to ready-to-submit", and `scripts/factory-wait.sh chain` waits 45 minutes and lists
   stages without `design`. Update both there.
8. Not yet brand-aware: `app-content` (landing page) and `tools/screenshots/compose.mjs` (store
   frames use `screenshots.json` colors but the house font).
9. The compliance gate matches words, not imports: `compliance.sh` greps the app **and
   FactoryKit** case-insensitively for ad and analytics SDK names (`amplitude`, `firebase`,
   `segment.com`, `adjust.com`, `applovin`…). A FactoryKit parameter named `amplitude` failed
   every app's gate on the first push (fixed in `4f38e1c` by renaming it). Any new kit code or
   a third-party package whose source contains those words will do the same.

## Useful commands

```sh
gh workflow run app-polish.yml -f slug=<slug> -R vladmarian20005/appfactory            # the taste gate (chain on)
gh workflow run app-polish.yml -f slug=<slug> -f chain=false -R vladmarian20005/appfactory
gh workflow run app-submit.yml -f slug=<slug> -f confirm=SUBMIT -R vladmarian20005/appfactory   # TestFlight upload
gh run list -R vladmarian20005/appfactory --limit 15
node tools/design/tells.mjs <slug>                    # slop tells in code
node tools/design/render.mjs apps/<slug>/design/mock-*.html
node tools/icon.mjs <out.png> --svg <icon.svg>
SIM_UDID=<udid> .github/scripts/verify-app.sh <slug> && SIM_UDID=<udid> .github/scripts/design-captures.sh <slug>
```

State per app is `apps/<slug>/state.json` (`stages.design`, `polish_attempts`, `fix_attempts`).

## Session 2 · 12 September · closing the gate and the loop

The owner's question was "is it live, will all apps go through the taste workflow, and what
else does the workflow need". The answers were: the pipeline is live and both apps are on
TestFlight but **neither is live on the App Store** — both sit at `PREPARE_FOR_SUBMISSION`
and `app-release` has never run; and **no, not all apps went through it**, because the taste
bar was an edge in the chain rather than a gate.

**The bar is now a gate.** `design` was recorded by `app-polish` and required by nothing:
`app-submit` asked for verify, compliance and pages; `app-release` asked for submit. So the
bar held only while the chain ran in order, and any direct dispatch walked around it. Worse,
`tallies` — no `DESIGN.md`, nine hard tells — sat in exactly the shape `awaiting.mjs` selects,
so the half-hourly cron would have uploaded it unattended the moment its App Store Connect
record existed. Now: `app-submit` requires `design`; `awaiting.mjs` skips an app whose design
is not ok; and `app-release` refuses a build nobody has run on a phone, which is what
`device_tested` and `storekit_verified` were always for — the ship skill has said "the gate
refuses to pass on your word" since it was written, and no gate read them.

**The blank-capture mystery was two bugs, and neither was slowness.**
`tools/qa/check-shot.mjs` failed any capture where under 4% of pixels differed from the
background. That is not a property of an unrendered screen, it is a property of a calm one —
and `TASTE.md` asks for calm. Tallies' fully-drawn empty state measures 2.8%. Measured over
every capture in the repository, a rendered screen fills 68–123 of 128 cells and the sparsest
real one still fills 30, against 0 for a window that never drew, so the check now asks *where*
the content is rather than how much of it there is. This was not what bit Tidepour (its
screens measure 39–48% and always passed), so it is a latent bug that would have hit the first
genuinely minimal app. For the genuine blanks: captures now build **Release**, since Swift's
Debug `-Onone` makes Tidepour's generator 23–31× slower and does the same to SwiftUI view
construction, which is the part that must finish before a first frame exists; and when nothing
draws inside the window, `sim.sh` now reports whether the app is running, stuck or gone plus
its last log lines. Waiting longer had been the answer twice, and a threshold is not a
diagnosis.

**The brand reaches the store.** Both apps set their identity in New York — Quizday's
`DESIGN.md` calls the serif "the one thing no competitor in this category has" — and both
store frames were headed in SF Pro over a screenshot of a newspaper. `compose.mjs` takes
`font` from `screenshots.json` and renders in WebKit, which is what resolves `ui-serif`.

**The framework question is decided: no third-party UI packages.** The deciding evidence is
the critics' own output — of the fourteen fixes they asked for across both apps, not one wants
an effect a library supplies. Two structural reasons besides: a continuous emitter never
settles and the capture tooling waits for a still screen, so every effect needs a
`Motion.isStill` wrapper anyway; and `tells.mjs` fails a win that calls none of the kit's
reward APIs, so a win built on Vortex would fail the taste bar. Reasoning in `CLAUDE.md`.

**The kit stopped talking for the app.** `OnboardingView(nextTitle:finishTitle:)` and
`PaywallView(subhead:cta:)`. Both critics asked for this independently; it was the
most-requested fix in the repository, and FactoryKit was violating `TASTE.md` on every app's
first and last screens.

**The loop is closed at the far end.** `app-monitor` runs daily: version review state, build
expiry, and reviews at three stars or under, red-ticking when something needs a person.
Nothing ran after `release` before this.

**appmonkey was taught the gate** (`c142043` there): its chain wait was 45 minutes, set before
`app-polish` existed, so it timed out on every app; its stage line omitted `design`; and it
had no verdict for "still fails TASTE.md after its polish passes", which is the one outcome
that stops and asks for a person. Now `TASTE_FAILED`, and 180 minutes.

## Open questions for the next session, in order

1. **The owner's device pass, then the first `app-release` the factory has ever run.** This is
   now the only thing between the two apps and the store. Run the TestFlight build on a phone
   — the reminder firing, haptics, the share sheet, a real sandbox purchase — then set
   `device_tested` and `storekit_verified` in `state.json`. `app-release` refuses without
   them. It has never run successfully for any app and it is the one workflow that touches
   Apple irreversibly, so watch it rather than firing it and walking away.
2. **Does the Release capture change hold in CI?** Verified locally (tallies and quizday build
   and capture Release on Xcode 16.3); the first CI exercise is the `app-verify` dispatched at
   the end of this session and whatever `language-drills` does next. If a Release build breaks
   something, `SIM_CONFIG=Debug` restores the old behaviour in one place.
3. **Watch the second critique on a fresh app.** Unchanged from last session and now the
   biggest unknown in the gate: both apps passed on their first polish pass, so nothing has
   exercised the "out of polish passes → a human" path, or a second critique that disagrees
   with the first. `language-drills` is the candidate.
4. **`tallies` is blocked, and someone has to choose.** It has nine hard tells, no `DESIGN.md`,
   and is now correctly refused by both submit paths. Either run it through `app-polish`
   before creating its record, or shelve it in `STATUS.md`. Leaving it is fine; it can no
   longer ship by accident, which was the actual danger.
5. **The three FactoryKit additions the framework analysis identified**, in priority order,
   each replacing a third-party package with a first-party engine:
   `burst(trigger:_:at:)` — the short impact particle, which is genuinely missing (`confetti`
   is a 2.8 s win-tier celebration, wrong scale for a tile landing); `Haptics.sustain` /
   `Haptics.play(_:)` on Core Haptics, since all ten current entry points are instantaneous
   and `TASTE.md` asks for weight *during* an action; and `brandTexture` on SwiftUI shader
   effects, so atmosphere is not 1400 hand-drawn `Canvas` strokes as in Quizday's `PaperGrain`.
   **Unverified and must be proven by one CI run first:** that SwiftPM compiles `.metal`
   sources in the FactoryKit target and `ShaderLibrary.bundle(.module)` resolves them on
   Xcode 26, and that shader effects survive `ImageRenderer` inside `ShareImage.render`.
   Never name a parameter `amplitude`.
6. **`app-compliance` cannot see a third-party package's privacy manifest.** It checks only
   `$ios/PrivacyInfo.xcprivacy`, and its SDK-name grep does not reach an SPM checkout, which
   lands beside `App/` rather than inside it. Moot while the no-dependency rule holds; it is
   the gate to fix first if that rule is ever relaxed.

## The prompt to start the next session with

```
Read docs/HANDOFF.md in appfactory, then TASTE.md and CLAUDE.md.

The taste bar is a real gate now, the framework question is decided, and app-monitor
watches what happens after release. Quizday and Tidepour are on TestFlight and neither
has ever been submitted for review — app-release has never run for any app.

Your job this session, in order:

1. Get the first app into App Review. The device pass is the owner's; app-release now
   refuses a build with no device_tested on record. Watch the run — it is the one
   workflow that touches Apple irreversibly and it has never succeeded.
2. Watch language-drills through the gate. It is the first app to go through the whole
   chain with the new code, and the first chance to see a second critique, or the
   "out of polish passes → a human" path that nothing has exercised yet.
3. Then the FactoryKit additions in open question 5, cheapest first — burst, then
   Core Haptics. Prove Metal-in-SwiftPM on one CI run before committing to brandTexture.

Great UX, great UI is the bar. Ask before anything that reaches Apple.
```
