# The taste bar

The first two apps through the factory came out working, compliant and joyless. System-gray
screens, white cards, one accent color, an SF Symbol where the art should be, a win that was
a sheet with a checkmark, and copy that recited the business model at the player: "No timer,
no lives, no coins. Nothing here expires and nothing here runs out." Nobody screenshots that.
Nobody shows it to a friend. Next to an app with worse engineering and more heart, it loses.

This is the bar every app clears. The direction stage writes to it, the build builds to it,
the critic scores against it and the polish stage closes the gap. It is a gate, like
compliance: an app that builds, passes verify and fails this is not done.

## The test

Would a stranger, shown one screenshot, know which app it is — and want it? Would they
screenshot the win and send it to someone?

If the honest answer is "it's a clean template", it fails.

Calibrate against apps people love for how they feel, not what they do: Duolingo's lesson
complete, Wordle's share grid, (Not Boring)'s tactility, Carrot's voice, Alto's Odyssey's
atmosphere, Things' restraint, Flighty's information design. Take their standard, never
their look.

## Seven things every app has

1. **An idea, not a category.** One sentence that describes a world, not a feature. Not "a
   color-sort puzzle" but "a tide-pool apothecary at dusk, pouring glowing tinctures between
   hand-blown vials." Not "daily trivia" but "a morning quiz show hosted by a know-it-all owl,
   ten questions over coffee." The idea chooses the palette, the shapes, the sounds and the
   words. When two choices are equal, take the one that is more *this app*.

2. **A signature interaction.** The verb the user performs most, built so well it is
   satisfying on its own the thousandth time: anticipation (it lifts, it leans), action with
   weight (a spring, not an ease), follow-through (it lands, settles, the phone taps back, a
   tone plays). The pour arcs and fills and the liquid wobbles level. The answer card snaps,
   the right one glows. This is not polish. It is the product.

3. **A reward.** Finishing the loop is a moment, choreographed over about 1.5 seconds:
   something moves, a number counts up, something bursts, the phone answers, and the words
   are warm and specific. Wins have tiers — a clean sweep is louder than a pass, a new best
   louder still. Never a sheet with a checkmark and "Level cleared".

4. **A look of its own.**
   - A canvas with atmosphere: its own color, a wash, a glow, a mesh, a texture drawn in
     Canvas. Never `systemGroupedBackground` with white cards on it.
   - A palette of five or six named colors with jobs, in light and dark, with a second voice
     beyond the accent. Dark mode designed, not inverted.
   - Type with character. A display face — SF Rounded, SF Expanded, New York, SF Mono for
     numbers — used big: hero numbers at 80–120 points through `brandDisplay`. One thing on
     every screen is obviously the most important.
   - A shape language: one distinctive shape that repeats (the vial, the ticket stub, the
     pill) and one corner radius.
   - Art for heroes, onboarding, empty states and the paywall: drawn as SVG and rendered into
     the asset catalog, or built from SwiftUI shapes when it has to move part by part. An SF
     Symbol blown up to 88 points is not art.

5. **A voice.** Someone is talking and they have a personality that fits the idea: the owl is
   smug and kind, the apothecary calm and a little mystical. Short, specific, varied: praise
   and near-miss lines come from pools of at least six, so the tenth win does not read like
   the first. Buttons say what happens — "Pour it", "Next question" — not "Continue".

6. **Life.** Every touch answers inside a frame: a press state, a haptic. State changes move
   — slide, scale, swap with `matchedGeometryEffect` — so the eye follows cause to effect.
   Something slow and ambient keeps the screen alive (a glow breathing, bubbles rising), quiet
   enough to ignore.

7. **Something to share.** The result renders to an image (`ShareImage`) that looks good in a
   group chat: the brand, the score, the day, a flourish. A line of text is the fallback.

And an **icon** that is a drawing of the idea — `design/icon.svg` — never a letter or a
number on a gradient.

## The product is not the pitch

The store listing sells the wedge: no ads, every level solvable, nothing runs out. The app
*is* those things and does not say so. Inside the product the absence of ads is felt as calm,
not announced in footers. The paywall may state the promise, and at most one onboarding page.
Nowhere else.

Nor does the app explain itself in text. "Tap a tube, then tap the one to pour it into" means
the affordance failed. Make the first tube pulse, play a ghost hand through the first move,
and let the teaching disappear once it has worked. VoiceOver hints are the exception: they
should explain.

## Slop tells

Any one of these fails the critique. They are what the first two apps shipped with.

- The canvas is `Color(.systemGroupedBackground)` (or plain white or black), with content in
  white rounded cards.
- One accent color on gray, with green and red for right and wrong the only other color.
- An SF Symbol scaled up as the hero of onboarding, an empty state, a result or the paywall.
- A result that is "8 out of 10" in a card followed by "Come back tomorrow".
- Stats as a row of identical number tiles with gray captions.
- A win shown as a `.sheet` at `.medium` with a checkmark seal.
- Copy that explains the business model or the controls inside the product.
- Screens that are a `List` of `Label`s, or a `ScrollView` of identical cards.
- State that jumps; `.easeOut(duration: 0.16)` the only motion there is.
- The icon is text on a gradient.
- Nothing on any screen bigger than `.largeTitle`.
- Praise that never changes.
- The kit's own words on the app's first and last screens: onboarding ending in "Continue" /
  "Get started", a paywall button reading "Continue". Name them —
  `OnboardingView(nextTitle:finishTitle:)`, `PaywallView(subhead:cta:)` — in the app's voice.
  A trial still wins the paywall button, because App Review wants the trial named on it.
- Type frozen at a point size: `.font(.system(size: 44))` on screen, or a `-> Font` helper that
  returns one. It looks identical at the largest accessibility setting as at the default, so
  the design quietly stops working for the people who need it most. Say the same size with
  `scaledFont(size:)` or `brandDisplay(size:)` and it scales. There is no exception, including
  a share card: `ShareImage.render` pins Dynamic Type to `.large` for the render, so a card
  asks for a size through `scaledFont` and gets exactly that size on its fixed canvas. A card
  is the one place the pinning is right — it is a picture going into someone else's chat, and
  it has to lay out the same for everybody — and the pinning lives in the kit, once, so no app
  has to argue the case in a comment. Decided 12 Sep 2026, after `app-compliance` failed an app
  for the frozen sizes this file used to bless and left the pipeline with no legal move.

`node tools/design/tells.mjs <slug>` finds the mechanical ones in the code; its FAILs are the
list above. The critic finds the rest in the screenshots.

## Games need juice

A game is judged on feel before rules. Every action gets a press, anticipation, motion with
weight, an impact (a squash, a puff of particles, a haptic, a tone) and a settle. Finishing a
unit — a tube, a row, a question — gets a small celebration; finishing a level a big one.
Streaks and combos escalate: the tone climbs the scale, the burst grows. A wrong move is
forgiven with a gentle shake, never a buzzer.

Sound is `Tones`: short synthesized tones on an ambient session, so the silent switch mutes
them and the user's music keeps playing, with `SoundsToggle()` in Settings. A game without
sound says why in DESIGN.md.

## What stays standard

The system owns its chrome, and chrome only looks right when it is the system's: `TabView`,
`NavigationStack` and its toolbar, sheets, alerts, `Toggle`, `Picker`, `Menu`, `ShareLink`,
and buttons as `Button` with a system style — `.brandProminent()` is the system's prominent
style in the brand's tint. Built with the iOS 26 SDK these become Liquid Glass. Glass belongs
to that navigation layer. The content under it — boards, cards, tiles, art — is yours to draw,
on the brand's canvas.

Keep: Dynamic Type (`brandFont`, `brandDisplay`, `scaledFont`), Reduce Motion (FactoryKit's
motion handles it), VoiceOver labels on everything drawn, no third-party dependencies, and iOS
17 as the deployment target, with newer APIs behind `if #available`.

## Motion and the capture tooling

The simulator capture waits for the screen to stop changing. That is not a reason to build a
still app. Looping and ambient motion goes through FactoryKit — `ambientFloat`, `breathing`,
`brandBackground(drift:)`, `confetti` — which stands still when the app is launched with
`-stillFrames`, and `verify-app.sh` launches every capture that way. One-shot effects freeze
at their peak under it, so a capture of the win shows the win. Your own looping animation
checks `Motion.isStill`.

The critic sees motion through qa.json's `moments`: the app plays its own signature
interaction and its win on a `-demo <name>` launch flag, and `design-captures.sh` films it.

## FactoryKit's vocabulary

| Need | Use |
| --- | --- |
| The look, set once at the root | `Brand`, `.brand(AppBrand.brand)` |
| The canvas | `.brandBackground()` — also clears List and Form gray |
| A content surface | `.brandSurface()` |
| Display type | `.brandFont(.largeTitle)`, `.brandDisplay(size: 96)` |
| The primary action | `.brandProminent()` |
| Tappable content — tiles, cards, pieces | `.buttonStyle(.pressable)` |
| Springs | `Motion.snappy`, `.bouncy`, `.gentle`, `.pop`; `withMotion { }` |
| Entrances | `.popIn(delay:)`, staggered 0.04–0.08 s |
| Ambient life | `.ambientFloat()`, `.breathing()`, `brandBackground(drift: true)` |
| A wrong answer | `.shake(trigger:)` |
| Wins | `.confetti(trigger:power:)`, `CountUp(to:onTick:)` |
| Touch | `Haptics.tap`, `selection`, `soft`, `rigid`, `thud`, `impact(_:)`, `success`, `celebrate` |
| Sound | `Tones.shared.play(.pop / .success / .fanfare / .miss / .step(n))`, `SoundsToggle()` |
| Sharing | `ShareImage.render { … }` into `ShareLink(item:preview:)` |
| Illustration | `design/art/<name>.svg` → `node tools/design/art.mjs` → `Image("<Name>")` |
| Palette checks | `node tools/design/contrast.mjs <fg> <bg> …` |
| Onboarding with art | `OnboardingPage(title:subtitle:art:)` |
| A paywall with art | `PaywallView(…, hero: { … }, onDone:)` |

## The rubric

The critic scores each line 1–5. A 3 is a competent system app, and on the first five lines
that is a fail.

| | 1 | 3 | 5 |
| --- | --- | --- | --- |
| Idea | none visible | a theme in the colors | every screen unmistakably this world |
| Look | system defaults | a palette and a font | a canvas, type and shapes you would know from one crop |
| Signature interaction | tap and it changes | it animates | you want to do it again |
| Reward | a sheet | some confetti | choreographed, tiered, worth sharing |
| Voice | labels | friendly | a character, varied, never the pitch |
| Craft | cramped, misaligned | tidy | hierarchy, rhythm, dark mode designed, large text holds |
| First minute | onboarding of symbols | branded | the first ten seconds make a promise the app keeps |

**Pass:** no FAIL from `tells.mjs`, none of the slop tells in the screenshots, Idea, Look,
Signature interaction, Reward and Voice at 4 or more, Craft and First minute at 3 or more.
