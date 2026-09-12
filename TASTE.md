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
screenshot the win and send it to someone? And on Thursday, with nothing prompting them,
would they open it again?

If the honest answer is "it's a clean template", it fails. If it is "it's beautiful, and I
have seen everything it does", it fails too.

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

## The second session

Those seven are what an app is like in a screenshot. This section is what it is like on
Thursday, and the factory has been failing it silently because nothing downstream can see it.

The evidence, from the five apps built so far. Each one specifies its win animation to the
millisecond and its reason to come back in a single sentence, copied between specs: "three
screens, one loop: open, play today's ten, see the streak, come back tomorrow." It shows.
Quizday holds thirty rounds and picks with `dayNumber % rounds.count`, so on day 31 it deals
day 1's ten questions back in the same order, forever. Tidepour's generator climbs to seven
colors at level 26 and its par bar saturates at level 36, so every board from there to level
10,000 is the same board — the exact complaint its own spec mocks the competition for.
Thousand has the best content scheduler in the repo and caps the session: sweep the bench and
there is nothing else it will give you. The word `difficulty` appears 332 times in Quizday and
not once does any code read it to decide what to serve. The word `mastery` appears once in the
repository, in prose. `unlock` appears fifty-odd times and every single one is a purchase.

They are lovely and there is no reason to open them twice. Decided 12 Sep 2026.

### Pull, not push

Every spec here is written as a subtraction — no ads, no lives, no coins, no timer, no
streak, nothing runs out, a missed day costs nothing. That wedge is right and it stays: those
are the mechanics the incumbents extract with, and the reviews we build from are people
saying so in their own words.

But each of them is a real thing bent into a weapon. The factory removed the weapon and never
put the real thing back, and an app with nothing of either in it is not calm, it is weightless.
So: **take the pull, refuse the push.** Pull is wanting to know what the next one is. Push is
owing the app something.

| Theirs | What it deforms | We take | We refuse |
| --- | --- | --- | --- |
| Lives | stakes | a run that can still be saved; a perfect still intact | anything that ends play, or costs money to continue |
| Streak counters | continuity | that the app remembers you, and shows it unasked | a number that shames, a flame that dies, a notification that guilts |
| Countdown timers | tension | pressure the player opted into — a chain that decays, a bonus fading | a clock on a screen someone opened for calm |
| Coins and gems | something worth working toward | things earned by playing well | anything bought, and anything that runs out |
| Energy meters | pacing | a day's serving that feels complete, not cut off | being made to wait, or to pay to keep going |

A missed day still costs nothing. Nothing still runs out. Every store promise stays true.

### What every app owes the second session

1. **Something at risk, that costs only the run.** If nothing can be lost, nothing that
   happens matters. A chain that breaks, a perfect that spoils, a par you can still beat — and
   when it goes, it costs this run and nothing else. Never a life, never progress already
   earned, never tomorrow.

2. **A curve that is still climbing long after anyone is counting.** The level after which
   every session is the same is where players leave, so it has to be further out than they
   get: `Ladder` computes it as `flattensAt`, and the gate fails a curve that stops inside
   150 sessions. When one dimension saturates — colors, speed, depth — the next one opens.
   Say in DESIGN.md what session 5, 50 and 500 are like, where the ladder does stop, and
   what happens past it.

   Not "a dial with no ceiling". That was this file's first answer and rebuilding Tidepour
   against it showed it forces a lie: a puzzle whose every board is solver-verified has a
   hardest board, and the open dial only demanded solutions no board of that shape contains —
   which produced a flat, noisy curve costing six seconds a level to generate. A bounded
   ladder, stated honestly, beats an unbounded one that is not true.

3. **Content that knows what it has already served.** What comes next is *chosen* — from what
   the player got wrong, has not seen, or just barely got right. Never `%` over a fixed array,
   never uniform random, never a `difficulty` field that is written and displayed and never
   read. The app is paying attention, and the player can tell.

4. **Something earned by playing.** At least one thing that arrives because someone played
   well, not because they paid: a mode, a board type, a color, a title, a piece of the world.
   A paywall is a fine door. It cannot be the *only* door.

5. **An ending that opens.** A session ends by naming what is waiting. Thousand gets this
   right and is the standard: "The bench is swept. Twenty-two tiles are drying, eleven are
   ready tomorrow." Specific, earned, true, and no guilt in it. Never a score in a card over
   "Come back tomorrow."

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

And the tells of an app nobody opens twice:

- Content chosen by `%` over a fixed array, or drawn uniformly at random: it repeats, and it
  never ramps.
- A `difficulty` — or `level`, or `strength` — that is stored and shown and never read to
  decide what the player gets next.
- A ladder whose last rung arrives in the first week, after which every session is identical
  (`Ladder.flattensAt` under 150).
- Every unlock in the app is a purchase; nothing is earned by playing.
- Stats that accumulate where nothing consults them: a per-category accuracy on a Progress
  screen that chooses nothing.
- The session cannot be lost, extended, or done badly — there is no run, only a list to finish.
- The end of a session is a number and "Come back tomorrow".
- The reason to return is a streak counter, and the streak does nothing but count.

`node tools/design/tells.mjs <slug>` finds the mechanical ones in the code; its FAILs are the
list above. The critic finds the rest in the screenshots and the ladder strip.

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
| Difficulty that keeps climbing | `Ladder([.init("par", from: 9, every: 3)])`, `ladder.climbsForever` |
| What to serve next | `Mastery.next(from:count:avoiding:)`, `mastery.record(_:correct:)` |
| What is at risk this session | `Run` — `hit()`, `miss()`, `chain`, `isClean`, `tier(beating:)` |
| What playing earns | `Earned`, `earned.next(after:)` for what a session ends on |
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
| Escalation | every session is identical | a ladder that stops in week one | session 500 is a different game from session 5 |
| Pull | nothing waits | a streak counter that counts | you want to know what the next one is |

The last two are judged over time, not in a still: from the ladder strip, the code that chooses
what comes next, and what the app says when a session ends. For an app with no loop to climb —
a counter, a log — Escalation is scored on whether it deepens as the player's own data
accumulates, and an app that looks the same at 500 entries as at 5 scores 1.

**Pass:** no FAIL from `tells.mjs`, none of the slop tells in the screenshots, Idea, Look,
Signature interaction, Reward, Voice and Pull at 4 or more, Craft, First minute and Escalation
at 3 or more.
