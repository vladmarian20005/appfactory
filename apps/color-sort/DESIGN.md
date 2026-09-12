# Tidepour · design

## The idea

**A tide-pool apothecary at dusk: a rack of hand-blown vials standing in the wet flat, each
holding a different colour of light, and the work is decanting one glow into another until
every vial holds a single colour.**

Three words: **lit, wet, unhurried.**

What it is NOT: the category. All forty-nine water-sort competitors are the same app — crayon
primaries as flat rectangles, a white or pale-grey sheet behind them, a coin counter, a rewarded
-video button shaped like a television, a cartoon shovel mascot, and a "Level Cleared!" banner
in a bevelled ribbon. Tidepour is a dark shore at the blue hour. Nothing in it is a rectangle of
flat colour on paper; every unit of liquid is light *inside glass*, standing in water, throwing a
ring on the flat underneath it.

Why a tide pool and not an arbitrary skin: the spec's wedge is that **every board was solved
before it was served** — there is always a way out and the app will show it. A tide pool is the
one place where that is literally true: the water goes out, the way is revealed, and it is the
same for everybody who walks down at the same hour. The daily puzzle is the tide coming in on
schedule. The hint is the line already charted across the flat. The idea chooses the ink-blue
canvas, the mint that lights things, the serif numerals, the kelp fronds, and the voice of
somebody who keeps the pool and has walked this shore a thousand times.

## Who and when

He is 34, plays in eight-minute pieces — the bus, the queue, the ten minutes before sleep — and
wants something that does not shout, does not interrupt and cannot be lost. The reviews the
category earns are all one complaint in different words: "an ad after every level", "I lost 400
levels", "it gave me a board that can't be solved". The feeling Tidepour sells is **certainty
without pressure**: it is always solvable, it always saves, it never asks for anything, and the
screen is a calm place at the end of the day.

## The play

Pour the rack clean in as few moves as the charted line, and keep going up a shore that keeps
getting deeper. Written 12 Sep 2026, after the first build shipped without this section and
nobody noticed the game stopped being a game at level 36.

**The session.** Eight minutes, three or four racks. It ends when he stops, not when the app
says so; nothing is rationed and nothing waits for tomorrow.

**At risk.** The charted line — the solver's own optimal move count, shown as a rail that fills
as he pours. Going over it costs the clean sweep for that rack: the win is quieter, the confetti
does not fire, and the verdict says so kindly. It costs the rack and nothing else. There is no
life, nothing to buy back, and the rack stays cleared. A replay can still beat it, and `Results`
keeps the best moves, so an over-par board is an open question rather than a loss.

**The ladder.** `LevelGenerator.ladder`, and the numbers are measured rather than reasoned —
every row below is a real generated board, verified solvable with par proven optimal.

| Rack | Colours | Depth | Par | Generates in |
| --- | --- | --- | --- | --- |
| 1 | 3 | 4 | 8 | instant |
| 9 | 4 | 4 | 11 | instant |
| 33 | 7 | 4 | 23 | 12 ms |
| 65 | 11 | 4 | 34 | 53 ms |
| 81 | 13 | 4 | 41 | 112 ms |
| 105 | 13 | 5 | 55 | 1.1 s |
| 155 | 13 | 6 | 69 | 2.3 s |
| 300 | 13 | 6 | 68 | 2.0 s |

A light comes into the flat every eight racks until there are thirteen at rack 81; the glass is
then blown deeper, five measures at 105 and six at 155. **The ladder stops changing at rack
169** — `ladder.flattensAt` says so out loud — which is most of a year at a rack a day.

The first version of these numbers stopped colours at nine and left racks 31 to 124 identical,
ninety-four of them, and the critic caught it from `ladder.png` in one pass while three comments
in the generator still claimed depth changed at 45. The longest plateau is fifty racks now, at
105–154, and every rack from 1 to 200 has been generated and checked: solvable, and with a line
the solver could *prove* is the shortest. That proof is the ceiling on all of this. Every board
is dealt, solved and thrown away if the solver cannot finish it, and beyond six measures the
search returns paths it cannot call minimal — so `make` refuses any candidate it could not
prove, and the rack stops getting deeper rather than letting par quietly stop meaning what the
app says it means. If the shore ever needs to go further, the next dimension is a second rack on
the same flat, not a seventh measure.

Deep racks cost one to two seconds to deal, against milliseconds in the shallows; that is the
price of the verified line, and it is spent behind the dealing animation.

**What comes next.** The rung. Each rack's board is its level number seeded, dealt up to ten
times, and kept only when the solver both finishes it and finds a line at least as long as the
bar for that shape. Nothing is random from the player's side: rack 41 is the same board on every
phone and after every reinstall.

**Earned.** `AppInfo.earned` — three milestones, all of them free, none of them purchasable.
The thirteenth light at rack 81, tall glass at 105, deep glass at 155. Each is the ladder's own
next opening, named at the win the moment it is crossed; when nothing was crossed, the win names
the one still coming ("Tall glass at rack 105."). The paywall stays exactly where it was, at rack 60
— it buys *more shore*, and these three arrive whether or not it is ever paid.

**The ending.** The win ends on what opened, or on what is still on its way, above the two
buttons — never on a number over "Come back tomorrow". The daily's own ending sends him back to
the shore with the streak intact.

**The daily** climbs too, now. It used to be six colours and par 18 on every date the app would
ever see, which made the one board everybody plays together the flattest thing in the game. It
walks a fortnight up its own ladder and back — rack-equivalent 6 to 45 — so the shared board in
March is not the shared board in September.

## The look

### Canvas

Deep water, never grey and never black. A nine-point mesh — dusk sky at the top, cold water
through the middle, a lantern-warm pool glow at the bottom — that drifts very slowly through
`brandBackground(drift: true)` and stands still for `-stillFrames` and Reduce Motion. Light mode
is **dusk in the shallows**; dark mode is **the same pool three hours later**, deeper and
colder, with the lantern glow the only warmth left. They are two different underwater blues, not
one blue and its inverse.

### Palette — six named colours with jobs

| Name | Job | Light | Dark |
| --- | --- | --- | --- |
| **Deep water** | the canvas | `#0F3340` | `#071F29` |
| **Shelf** | glass bodies, panels, surfaces | `#16414F` | `#0C2C38` |
| **Sea light** | primary type and glyphs | `#E9F6F2` | `#D6EEEA` |
| **Sounding** | secondary type | `#9DBAC0` | `#7F9FA8` |
| **Mint** | the signature: selection, the charted line, primary actions | `#4FE3D2` | `#5FEBDA` |
| **Lantern** | the second voice: streaks, par, the reward, the sun | `#FFB661` | `#F3A748` |
| **Kelp** | a tube completed | `#5FD8A9` | `#4FC79A` |
| **Ember** | a move that cannot be made — warm, never an alarm | `#FF8A57` | `#E87A4C` |

Red and green never mean right and wrong here. Ember is a warm refusal; Kelp is a tube that came
good. Both are liquid colours too, so neither reads as a system state.

### The eight liquids

Light in glass, not paint on paper: each is a top-lit vertical gradient of the named colour to a
30 % deeper mix of itself, with a specular stripe down the left sixth of the glass and a lighter
meniscus ellipse on the top surface.

`ember #FF8A57` · `tide #5CB2F0` · `lantern #FFD265` · `kelp #5FD8A9` · `dusk #B69AF5` ·
`coral #FF93AC` · `pearl #EADCC0` · `abyss #6E82E4`

The **Okabe–Ito palette stays exactly as it is** behind the unlock's colour-blind setting, and
the shape stamped on every unit stays with it. It is the one thing in this app that no
competitor has, and it is drawn into the new glass rather than replaced.

### Type

Display is **New York** (`.serif`): the move counter, the hero number on the win, the streak.
Body is SF. Hero numbers run at 96–110 points through `brandDisplay(size:)`, so one thing on
every screen is unmistakably the most important. Small tracked uppercase labels in SF —
`POURED`, `THE LINE · 13`, `POURS` — are the chart marks on the flat.

### Shape language

**The vial**: `UnevenRoundedRectangle` with a tight top (radius = width × 0.16) and a fully round
bottom (radius = width × 0.46). It repeats everywhere — the ladder's level chips are vials, full
when cleared and empty when not; the calendar's days are pool dots; the tab bar's Pour icon is a
drop. One corner radius everywhere else: **18**.

A completed vial gets a **glow ring** on the flat beneath it and a **kelp frond** — three arcs
drawn as a `Path` in the liquid's own colour — growing under it. That is how the eye reads the
board's progress without counting.

### Art

Five SVGs in `design/art/`, rendered into the asset catalog with `tools/design/art.mjs`:

| File | Where |
| --- | --- |
| `rack-at-dusk.svg` | onboarding 1 — a rack in the wet flat, one vial tipped and pouring |
| `charted-line.svg` | onboarding 2 — the solved line already laid over a rack |
| `high-tide.svg` | the paywall hero |
| `low-tide.svg` | the empty rack, for a board still dealing |
| `open-water.svg` | the flat running to the horizon |

The icon is `design/icon.svg`: a lit vial standing in a ringed pool, being poured into from
off-frame. Never a letter, never a number, never three rectangles on a gradient.

## The signature interaction

**The pour.** It is the only verb, it happens three hundred times an evening, and it has to be
worth doing the thousandth time.

| ms | what happens |
| --- | --- |
| finger down | The vial answers under the thumb: `.buttonStyle(.pressable)`, `Haptics.soft()`. |
| pick up | **Anticipation.** The chosen vial rises `unit × 0.34` and tips 5° toward nothing in particular, on `Motion.snappy`. Its rim lights mint, and the flat under it brightens. `Haptics.selection()`, `Tones.shared.play(.tap)`. |
| 0–180 | **The lift.** The vial leaves the rack: it rises `unit × 0.62`, travels 38 % of the way toward its destination, and rotates **40° toward it** about its own base — `Motion.snappy`. `Haptics.soft()` at the top of the lift. |
| 180–420 | **The arc.** A stream draws from the tipped mouth to the destination's mouth: a quadratic `Path` in the liquid's colour, 7 pt wide, with a soft outer glow at 0.35 and a bright core, trimmed 0 → 1 over `style.pourDuration` (0.24 s, or 0.45 s in calm mode). The source's top run is already gone; the destination's new units rise from zero height. |
| 420–620 | **The landing.** The destination's level **overshoots and settles** on `Motion.bouncy`, and its surface meniscus wobbles once. A splash ellipse blooms at the mouth and fades. `Haptics.rigid()`. `Tones.shared.play(.step(n))`, where n is how full the receiving vial now is — so filling a vial climbs the scale, and the last unit is the top note. |
| 620–760 | **The return.** The source vial swings back upright on `Motion.bouncy` and lands in the rack. |
| on completion | A vial that comes good gets `Haptics.impact(0.75)`, `Tones.shared.play(.success)`, a 26-particle burst in its own colour at 0.4 power, a held mint→kelp glow ring on the flat, and its kelp frond grows. |
| illegal | `.shake(trigger:)` on the vial, `Haptics.warning()` suppressed in favour of nothing louder than a `Tones.miss`. Never a buzzer, never red. |

Everything looping checks `Motion.isStill`; under `-stillFrames` the pour resolves in one frame
so a capture shows a finished board rather than a frozen half-pour.

**Teaching the first one, with no text.** On a board with no moves played, the vial the verified
solution wants first **breathes** — `.breathing()` on its glow ring, 2.4 s period — and stops
the instant the first pour lands, for good. There is no "tap a tube, then tap the one to pour it
into" anywhere in this app. The VoiceOver hint is the exception and does explain.

## The reward

**The tide goes out and the rack stands lit.** Full screen on the brand canvas — never a sheet,
never a checkmark seal — choreographed over about 1.5 seconds.

| ms | what happens |
| --- | --- |
| 0 | The board fades under a rising horizon; a sun in Lantern comes up over it with a soft glow. |
| 0–300 | The hero number counts: `CountUp(to: moves, onTick:)` in `.brandDisplay(size: 96)` inside a thin Lantern ring, over a small tracked `POURS`. Each tick is `Haptics.impact(0.35)` and `Tones.shared.play(.step(n))`. |
| 200 | The praise line sets under it, from the pool — `.brandFont(.title)`, warm and specific, naming the number. |
| 300–700 | The **start-to-the-line rail** draws itself: a hairline from `START` to `THE LINE`, with the player's dot travelling to where they finished against par. |
| 400–760 | The cleared rack rises into frame and lights **one vial at a time**, `.popIn(delay:)` staggered 0.06 s, fronds under each. |
| 500 | **Tiers.** Under par: `confetti(power: 1.4)`, `Haptics.celebrate()`, `Tones.fanfare`. At par: `confetti(power: 1.0)`, `Haptics.celebrate()`, `Tones.fanfare`. Over par: **no confetti at all** — a warm Lantern glow swells behind the rack, `Haptics.success()`, `Tones.success`. A clean sweep must be louder than a finish. |
| after | Buttons say what happens: **Take the next one** (prominent), **Pour it again**, **Share the rack**. |

**Share the rack** renders a card with `ShareImage`: the six cleared vials standing in the pool
on the brand canvas, the level, the pours against the charted line, the streak, the date. A line
of text is not the fallback here — the picture is the point.

## The voice

**The keeper of the pool.** He has walked this shore every evening for years, he is calm, a
little mystical, and he is pleased for you without making a performance of it. Short, specific,
concrete; he talks about light and glass and lines, never about apps.

Buttons say what happens: **Pour it**, **Take the next one**, **Pour it again**, **Show me**,
**Back**, **Refill**. Never "Continue", never "OK".

**Under par** (6, pooled, never the same twice running):
- "Shorter than the charted line."
- "You found a way I had not."
- "The line bends for you."
- "Fewer pours than the water needed."
- "That is the shortest route beaten."
- "Nobody walks it that clean by accident."

**At par** (6):
- "The rack is clean."
- "Every light found its glass."
- "Exactly the charted line."
- "Straight down the line, no wasted pour."
- "That is the shortest line there is."
- "Clean as the flat at low tide."

**Over par** (6, near-miss — warm, never a scold):
- "The rack is clean. The line was shorter."
- "You got there. The water knows a quicker way."
- "Every glass holds one light — that is the job done."
- "A few pours over the line, and still lit."
- "Not the short way, but the right end."
- "Done is done. The line will keep."

Nowhere in the product does it say "no ads", "no coins", "nothing runs out" or "no timer". The
paywall's promise line is the one place allowed to state the deal, and it already does. Inside
the app the absence of all that is *felt as calm*, not announced.

## Sound

`Tones`, on an ambient session, with `SoundsToggle()` in Settings: `.tap` picking a vial,
`.step(n)` climbing as a vial fills, `.success` when one comes good, `.fanfare` on a clean win,
`.miss` on a move that cannot be made. Warmed up when the board first appears.

## Screens

| Screen | What it is |
| --- | --- |
| **Pour** (`mock-1-play`) | The rack on the flat. A serif count over a `POURED / THE LINE · n` rail. The charted-line arc when a hint is armed. Back / Show me / Refill. |
| **Chart** | Today's pool, the streak as one hero number standing in the water, the month as pool dots, and the share card. |
| **Shore** | The ladder as a shelf of vials — full when cleared, empty when not — and what the unlock opens. |
| **Settings** | The system's, in the brand's tint, with sounds and the erase. |

## Tokens

```swift
import FactoryKit
import SwiftUI

/// Tidepour's look, from DESIGN.md. A tide pool at dusk: deep water, glass, and light.
enum AppBrand {
    static let brand = Brand(
        palette: BrandPalette(
            canvas:    Color(light: 0x0F3340, dark: 0x071F29),
            surface:   Color(light: 0x16414F, dark: 0x0C2C38),
            ink:       Color(light: 0xE9F6F2, dark: 0xD6EEEA),
            inkSoft:   Color(light: 0x9DBAC0, dark: 0x7F9FA8),
            accent:    Color(light: 0x4FE3D2, dark: 0x5FEBDA),
            onAccent:  Color(light: 0x04262A, dark: 0x021C20),
            highlight: Color(light: 0xFFB661, dark: 0xF3A748),
            success:   Color(light: 0x5FD8A9, dark: 0x4FC79A),
            miss:      Color(light: 0xFF8A57, dark: 0xE87A4C),
            extras: [
                Color(light: 0xFF8A57, dark: 0xF07C4C),   // ember
                Color(light: 0x5CB2F0, dark: 0x4C9EDC),   // tide
                Color(light: 0xFFD265, dark: 0xEFC055),   // lantern
                Color(light: 0x5FD8A9, dark: 0x4FC79A),   // kelp
                Color(light: 0xB69AF5, dark: 0xA286E6),   // dusk
                Color(light: 0xFF93AC, dark: 0xEC819B),   // coral
                Color(light: 0xEADCC0, dark: 0xD6C7A9),   // pearl
                Color(light: 0x6E82E4, dark: 0x6070D4),   // abyss
            ]
        ),
        type: BrandType(display: .serif,
                        displayWidth: .standard,
                        displayWeight: .bold,
                        body: .default),
        corner: 18,
        // Dusk in the shallows, and the same pool three hours later. Nine points, drifting.
        canvas: .mesh([
            Color(light: 0x14394A, dark: 0x0A2733), Color(light: 0x123745, dark: 0x08222D), Color(light: 0x16404E, dark: 0x0B2A37),
            Color(light: 0x0E3340, dark: 0x071F29), Color(light: 0x114150, dark: 0x0A2B38), Color(light: 0x0D303D, dark: 0x061A23),
            // Bottom centre, in dark, is the lantern on the water: the one warm point in it.
            Color(light: 0x0B2C38, dark: 0x051821), Color(light: 0x1A4A4A, dark: 0x163731), Color(light: 0x0A2A35, dark: 0x04151C),
        ])
    )

    /// The chart marks on the flat: small, tracked, uppercase, SF.
    static func chartLabel(_ size: CGFloat = 11) -> Font {
        .system(size: size, weight: .semibold, design: .default)
    }
}
```

Applied once at the root: `.brand(AppBrand.brand)` on `RootView` **and** on `OnboardingView`, so
the very first screen is already the shore.

## Slop we are avoiding

- `Color(.systemGroupedBackground)` with white cards. There is no white in this app.
- One accent on grey, with green and red for right and wrong.
- An SF Symbol at 88 points as the hero of anything.
- A win as a `.sheet` at `.medium` with `checkmark.seal.fill`.
- Three identical number tiles with grey captions.
- `.easeOut(duration: 0.16)` as the only motion in the app.
- Copy that explains the controls, or the business model, inside the product.
- Praise that never changes.
