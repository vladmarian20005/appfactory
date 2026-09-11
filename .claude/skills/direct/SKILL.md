---
name: direct
description: Design direction for an app before it is built — the idea, the look, the signature interaction, the reward, the voice, an icon drawn as SVG, art, and mocks of the key screens — written to apps/<slug>/DESIGN.md. Use for "direct <slug>", "design direction", "art direction", "make it look good".
---

# /direct <slug>

Requires `apps/<slug>/SPEC.md`. Produces `apps/<slug>/DESIGN.md` and `apps/<slug>/design/`:
the brief the build implements and the critic holds it to.

Read `TASTE.md` first, all of it. That is the bar. Your job is to decide, before any Swift
exists, what this app is like to use — specifically enough that a builder with no taste of
its own would still produce something people want to screenshot.

The spec was written by a market analyst. It knows what the competition gets wrong and what
reviewers love; it says nothing about how the app should feel, and its voice — "no ads, no
timer, nothing runs out" — is the store listing's, not the product's. Take the facts from it.
Leave the voice.

You are on a GitHub macOS runner with no GUI and nobody to ask. Commit **and push** as you go:
`git pull --rebase origin "$FACTORY_BRANCH" && git push origin HEAD:"$FACTORY_BRANCH"`
(`$GITHUB_REF_NAME` if `FACTORY_BRANCH` is unset). A commit that is never pushed dies with the
runner.

## 1. Who, when, and in what state

From SPEC.md: the person, the moment of their day, and the feeling they come for. The
reviewers' love quotes are the best evidence there is — "I'm very ill. This helps me focus on
something other than the pain" means calm and gentle is the job, whatever the category
usually looks like. Write it down in three sentences before anything else.

## 2. Look at the competition

The spec names the leaders. Download their App Store screenshots — outside the repository,
they are someone else's work:

    node tools/design/leaders.mjs "$RUNNER_TEMP/leaders" "<leader one>" "<leader two>" …

Read two or three from each. Write down the category's clichés (every color-sort app is
candy tubes on a flat pastel; every trivia app is a purple gradient and a timer bar) and the
polish bar the best of them set. The new app should be recognisably not any of them, and at
least as finished as the best.

## 3. Three ideas, then one

Write three different ideas, each one sentence that describes a world (see TASTE.md §1), with
a line each on palette, signature interaction and voice. Make them genuinely different — a
calm one, a playful one, a strange one. Pick the one that best fits §1's feeling and that
nobody in §2 owns. Keep the other two as "Roads not taken", one line each.

The idea has to survive the medium: SwiftUI, iOS 17, no 3D engine, no licensed art or fonts
(the SF families and New York are free to use), art drawn as SVG or SwiftUI shapes. A world
that needs a hand-painted illustrator is the wrong world for this factory.

## 4. Write DESIGN.md — first, whole, and pushed

**DESIGN.md comes before the mocks, and is committed and pushed the moment it has every
section.** The builder can build from a DESIGN.md with no mocks; it cannot build from mocks
with no DESIGN.md. The first run of this stage drew three mocks, an icon and five pieces of
art for Tidepour and ran out of turns before writing a word of it. Write the whole document
now, push it, then draw; revise it after the mocks if they change your mind.

Exactly these sections, in this order. Be concrete: numbers, hex values, timings, the actual
words. "Playful" is not a direction; "the owl raises an eyebrow and says 'Bold.' when you get
a hard one right" is.

```
# <Name> · design

## The idea
One sentence. Then three words for how it feels, and one line on what it is NOT (the
category cliché we refuse).

## Who and when
The three sentences from step 1.

## The signature interaction
The core verb, beat by beat with timings: what the finger does, what moves and how (spring
response/damping), the haptic, the tone, the settle. What makes it satisfying the thousandth
time. How the first one is taught without text.

## The reward
The win, beat by beat from 0 ms to about 1500 ms: what moves, what counts up, what bursts,
the haptic, the tone, the words. Tiers: a normal win, a great one, a best-ever. Small
rewards for completing a unit inside the loop.

## Look
- Palette: every BrandPalette role with light and dark hex and what it is for, plus extras.
  Checked: `node tools/design/contrast.mjs <fg> <bg> …` for ink, inkSoft and onAccent on
  what they sit on, both modes.
- Canvas: solid, wash, glow or mesh, and why.
- Type: display design, width and weight; where hero numbers appear and how big.
- Shape: the one distinctive shape, the corner radius.
- Art: each piece (mascot, hero, empty state, paywall picture), what it depicts, SVG or
  SwiftUI, and where it lives.
- Motion: the springs used and for what; what moves ambiently; what never moves.
- Sound: which Tones where, or why the app is silent.

## Voice
Who is talking, in one sentence, and three rules. Then the actual lines:
- onboarding: three pages, a title and a subtitle each
- praise pool: at least eight lines, and near-miss pool: at least six
- the win's headline for each tier
- empty states, the streak messages, the reminder notification
- paywall: headline, three bullets, and the one sentence of promise
- button labels for every primary action

## Screens
Every MVP screen from the spec: its one job, the hero element, the layout top to bottom, what
moves, and which parts are system controls. Note which mock shows it.

## Icon
The concept, the composition, the colors. Rendered at design/icon-1024.png.

## Share card
What the shared image shows, at 1080×1350.

## Tokens
The complete `AppBrand.swift` for the builder to paste:

    import FactoryKit
    import SwiftUI

    enum AppBrand {
        static let brand = Brand(palette: BrandPalette(…), type: BrandType(…), corner: …, canvas: …)
    }

Use `Color(light: 0x……, dark: 0x……)` for every role that differs by mode.

## Slop we are avoiding
The three slop tells from TASTE.md this genre is most prone to, and the specific thing this
app does instead of each.

## Roads not taken
The other two ideas, one line each.
```

## 5. Mocks

Draw the three screens that decide whether the app is loved, as HTML, at phone size:

- `design/mock-1-play.html` — the core screen mid-use: the board mid-pour, the question just
  answered, the list with something just added.
- `design/mock-2-win.html` — the reward at its peak.
- `design/mock-3-first.html` — the first thing a new user sees.

Then `node tools/design/render.mjs apps/<slug>/design/mock-*.html` and **Read every PNG**.
Score each against TASTE.md's rubric as if someone else made it. Fix what scores under 4 and
render again — at least one full revision, always. Draw iOS's own chrome (status bar, tab bar,
navigation bar) as iOS draws it; use `var(--safe-top)` and `var(--safe-bottom)`. Only draw
what SwiftUI can build: gradients, shapes, shadows, blur, materials, SF fonts
(`ui-rounded`, `ui-serif`, `ui-monospace`, `-apple-system`).

## 6. Icon and art

`design/icon.svg`: a drawing of the idea, `viewBox="0 0 1024 1024"`, full bleed, square
corners, the subject inside the middle 80%. Never a letter or number on a gradient.

    node tools/icon.mjs apps/<slug>/design/icon-1024.png --svg apps/<slug>/design/icon.svg
    sips -Z 120 apps/<slug>/design/icon-1024.png --out "$RUNNER_TEMP/icon-small.png"

Read both: it has to work at home-screen size, next to the leaders' icons from step 2.

Art pieces go in `design/art/<name>.svg`, each with a `viewBox`. Render one to check it —
`node tools/design/art.mjs apps/<slug>/design/art/<name>.svg "$RUNNER_TEMP/Check.imageset" --width 200`
— and Read the @3x PNG. The builder renders them into the asset catalog.

## 7. Commit

Commit DESIGN.md and design/ (mocks, their PNGs, icon, art) as `<slug>: design direction`,
and push.

## Done means

DESIGN.md has every section, with real hex values, timings and lines of copy; three mocks
exist, rendered and revised; the icon and every art piece render; the palette's contrast is
checked; everything is pushed. The builder should be able to implement the app without
making a single aesthetic decision you did not make first.
