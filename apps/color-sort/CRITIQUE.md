# Tidepour · critique

**Verdict: fail.** This is a correct, careful, well-accessible color-sort app wearing the
iOS settings-screen uniform — system gray canvas, white cards, system blue, SF Symbols, and a
win that is a medium sheet with a checkmark seal. The one thing that decides it: the app was
built with no design direction at all (`tells.mjs` FAILs `no-direction`; there is no
`apps/color-sort/DESIGN.md`, and `design/` was committed hours *after* the build), so the
tide-pool world in `design/mock-1-play.png` exists only as a mock — none of it reached a
single screen.

| | Score | Evidence |
| --- | --- | --- |
| Idea | 1 | Nothing on any screen says "tide pool at dusk": `qa/01-play.png` is crayon primaries on `systemGroupedBackground`, and the tabs read Play / Progress / Packs — a category, not a world. |
| Look | 2 | `tells.mjs` FAILs `kit-default-brand` and `gray-canvas` ×7; no `.brand()`, `.brandBackground()`, `brandFont` or `brandDisplay` appears anywhere in `ios/App/`, and dark mode (`qa/design/dark-01-play.png`) is pure black with the same blue — an inversion, not a design. |
| Signature interaction | 1 | The pour does not animate: `GameModel.pour` mutates `board` and returns (`ios/App/GameModel.swift:134`), `BoardStyle.pourDuration` (`Palette.swift:94`) is never read by anything, and the only motion in the app is `.easeOut(duration: 0.16)` on a tube lift (`TubeView.swift:64`) — the slop tell verbatim. |
| Reward | 1 | `PlayView.swift:46` presents `LevelClearedView` as a `.sheet` at `.presentationDetents([.medium])` whose hero is `checkmark.seal.fill` over "Level cleared" and "18 moves"; `tells.mjs` FAILs `no-reward` — no confetti, no `CountUp`, no `Tones`, no `Haptics.celebrate`. |
| Voice | 2 | Three fixed verdict strings (`PlayView.swift:276–278`) are the only writing with a pulse; against them the product recites the store pitch four times, including TASTE.md's own quoted failure line word for word at `StreakView.swift:80`: "No timer, no lives, no coins. Nothing here expires and nothing here runs out." |
| Craft | 3 | Genuinely tidy and the accessibility work is real — `ViewThatFits` header, symbol-only controls, a 240 pt board floor and a scaling calendar all hold at AX5 (`qa/design/ax-01-play.png`) — but nothing on any screen is bigger than `.largeTitle`, dark mode is undesigned, and the hint arrows collide with the tube mouths at AX sizes. |
| First minute | 2 | Onboarding is three SF Symbols (`AppInfo.swift:19–35`) whose third page is the business model, and the board then explains itself in text: "Tap a tube, then tap the one to pour it into." (`PlayView.swift:123`) — TASTE.md names that exact sentence as the affordance having failed. |

An App Store editor's answers: the screenshot I would put first is `qa/04-accessible.png`,
because the shape markers are the only thing on any screen that is not in every one of the 49
competitors — and I would not feature it. The weakest screen is `qa/02-progress.png`: a
white-card daily blurb, three identical number tiles with gray captions, a blue calendar grid
and the pitch in small gray type — five slop tells stacked on one screen. A stranger shown a
crop would say: "a water-sort game; there are forty of those."

## Captures missing

- **`qa/design/moment-*.png` — none exist.** `qa.json` has no `moments` key and
  `ios/App/LaunchOptions.swift` has no `-demo` flag, so the signature interaction and the win
  were never filmed. I scored both from the code instead, which is why they score 1 rather
  than "unknown": the code shows there is nothing to film.
- No dark or AX capture of the win (`05` is the paywall, not the cleared sheet).
- `apps/color-sort/DESIGN.md` does not exist.

## Slop tells present

- **Gray canvas with white cards** — `PlayView.swift:43`, `PlayView.swift:306`,
  `StreakView.swift:41`, `StreakView.swift:109`, `PacksView.swift:35`, `TubeView.swift:36`;
  visible on all five of `qa/*.png`.
- **One accent color on gray** — system blue is the tube outline, the hint badge, the verified
  seal, the calendar fill, the level squares, every button and the tab bar
  (`qa/03-packs.png`).
- **A win as a `.sheet` at `.medium` with a checkmark seal** — `PlayView.swift:46–55, 283`.
- **Stats as a row of identical number tiles with gray captions** — `StreakView.swift:68–72`,
  `StatTile` at `StreakView.swift:89`; see `qa/02-progress.png`, "9 / 9 / 16".
- **Copy that explains the business model inside the product** — `StreakView.swift:22`,
  `StreakView.swift:80`, `PacksView.swift:45`, `RootView.swift:114`, `AppInfo.swift:32`.
- **Copy that explains the controls** — `PlayView.swift:123`, `AppInfo.swift:23`.
- **An SF Symbol as the hero** — `checkmark.seal.fill` at 48 pt is the win
  (`PlayView.swift:283`); `drop.fill` at 40 pt is the empty/dealing state
  (`PlayView.swift:138`); all three onboarding pages use `OnboardingPage(symbol:)` rather than
  `art:`, though `design/art/` holds five drawn SVGs that were never rendered —
  `Assets.xcassets/` contains only `AccentColor` and `AppIcon`.
- **`.easeOut(duration: 0.16)` is the only motion there is** — `TubeView.swift:64`, the single
  `.animation` call in the app.
- **Nothing bigger than `.largeTitle`** — the largest type is the 30 pt `StatTile` number;
  `tells.mjs` WARNs `no-display-type`.
- **The paywall has no hero art** — `qa/05-paywall.png` is a bold title, a white bullet card
  and a blue Continue.
- **A silent game** — no `Tones` call anywhere, and no DESIGN.md to say why.
- **The result shares as text** — `StreakView.swift:33`, `ShareLink(item: shareLine)`, no
  `ShareImage`.
- **The shipped icon is not the drawn one.** `design/icon.svg` renders a lit vial standing in
  a dark tide pool (`design/icon-1024.png`), but
  `ios/App/Assets.xcassets/AppIcon.appiconset/icon-1024.png` is three flat rectangles on a
  navy gradient.

## Keep

- **The wedge is real and it is on screen.** "Solution verified" next to the move counter, and
  a hint that marks the source ↑ and the destination ↓ on the tubes themselves
  (`TubeView.swift:49–60`), is the guideline-4.3 answer stated better than a calendar states
  it. Keep the badge, keep the arrows, keep par next to moves.
- **The accessibility work, all of it.** The `ViewThatFits` header, the controls dropping to
  symbols past AX1 with VoiceOver labels intact, the 240 pt board floor, the calendar that
  scales its squares, and `label` in `TubeView.swift:92` reading a tube bottom-up as runs
  ("from the bottom, 2 blue, then red"). `qa/design/ax-01-play.png` and `ax-02-progress.png`
  hold where most apps break. None of this should be touched by the polish.
- **The Okabe–Ito palette plus a shape on every unit** (`Palette.swift:51`,
  `qa/04-accessible.png`). The shapes are the one thing in the app a competitor does not have.
  Redraw them into the new brand; do not drop them.
- **The tube silhouette** — `UnevenRoundedRectangle` with a tight top and a round bottom
  (`TubeView.swift:21`) is already the right shape language. It just needs to be made of
  glass.

## Fix, in this order

1. **Write DESIGN.md, then put the brand on — nothing else matters until this is done.**
   `tells.mjs` FAILs `no-direction` and `kit-default-brand`, which is a fail on its own. Take
   the direction that already exists in `design/mock-1-play.png`: an ink-blue tide pool at
   dusk (`#0C2430` → `#123340`), a mint that lights things (`#5FE3C0`), a lantern amber
   (`#E8A33D`), a coral (`#F4734A`) and a pale sand for type. Name them in `AppBrand.brand`,
   apply `.brand(AppBrand.brand)` at the root of `Tidepour.swift`, then delete every one of
   the seven `Color(.systemGroupedBackground)` / `secondarySystemGroupedBackground` /
   `tertiarySystemGroupedBackground` calls listed above and replace them with
   `.brandBackground(drift: true)` on the three screens and `.brandSurface()` on the cards.
   Dark mode gets its own values — deeper water, not black. *Next capture:* `qa/01-play.png`
   and `dark-01-play.png` are two different underwater blues, and neither has a white card on
   it.

2. **Build the pour. There is currently no pour.** `GameModel.pour` swaps the board in one
   frame and `BoardStyle.pourDuration` is dead code. In `TubeView`/`BoardView`: anticipation —
   the selected tube lifts and tilts with `Motion.snappy` (replace the `.easeOut(0.16)` at
   `TubeView.swift:64`); action — the source tips toward the destination and a liquid arc
   draws from its mouth over `style.pourDuration`; follow-through — the receiving level rises
   and overshoots with `Motion.bouncy`, the surface wobbles, `Haptics.soft()` on the tip and
   `Haptics.rigid()` on the land, `Tones.shared.play(.step(n))` climbing the scale as a tube
   fills. A tube that completes gets `Haptics.impact(.medium)`, a small burst and a held glow.
   Everything looping checks `Motion.isStill`. Add `-demo pour` and `-demo win` to
   `LaunchOptions.swift` and a `moments` block to `qa.json` so this is filmable. *Next
   capture:* `qa/design/moment-pour.png` exists and its frames differ — tilt, arc, splash,
   settle.

3. **Replace the win sheet with a moment.** Delete the `.sheet` +
   `.presentationDetents([.medium])` at `PlayView.swift:46–55` and the `checkmark.seal.fill`
   at `PlayView.swift:283`. Full-screen, on the brand canvas, over about 1.5 s: the finished
   rack of tubes rises into frame and lights one by one (`.popIn(delay:)` staggered 0.06 s),
   the move count runs up with `CountUp(to: result.moves, onTick:)` in `.brandDisplay(size:
   96)` above a small "POURS", `.confetti(trigger:power:)` at a power that scales with the
   tier — under par loudest, par next, over par a warm glow only — `Haptics.celebrate()` and
   `Tones.shared.play(.fanfare)`. Buttons say "Take the next one" and "Pour it again", as
   `design/mock-2-win.png` already has them. *Next capture:*
   `qa/design/moment-win.png` shows a full-bleed win with a hero number, not a half-height
   sheet.

4. **Cut the pitch out of the product and write a voice for what is left.** Delete the copy at
   `StreakView.swift:80` and `StreakView.swift:22`, the second sentence at `PacksView.swift:45`
   ("There is no subscription…"), the footer at `RootView.swift:114`, and onboarding page
   three (`AppInfo.swift:32`) — the paywall at `AppInfo.swift:44` is the one place allowed to
   say it, and it already does. Then give the app a keeper-of-the-pool voice: at least six
   pooled clear lines ("The rack is clean.", "Every light found its glass.", "Shortest line
   there was — 13 pours.") and six near-miss lines, so the tenth win does not read like the
   first. Buttons say what happens: "Pour it", "Take the next one", not "Continue". *Next
   capture:* no screenshot contains the words "no coins" or "nothing runs out" outside the
   paywall.

5. **Make the first minute a promise.** Render `design/art/*.svg` through
   `node tools/design/art.mjs` into the asset catalog — `Assets.xcassets` currently holds
   nothing but `AccentColor` and `AppIcon` — and switch `AppInfo.onboarding` to
   `OnboardingPage(title:subtitle:art:)` with `rack-at-dusk` and `charted-line`, as the two
   pages that are left after fix 4. Ship the icon that was actually drawn: copy
   `design/icon-1024.png` (the lit vial in the pool) over
   `ios/App/Assets.xcassets/AppIcon.appiconset/icon-1024.png`. Then delete
   `PlayView.swift:123` — instead, pulse the tube the verified solution wants first and let
   the pulse stop after the first successful pour. *Next capture:* onboarding shows a drawing,
   the board carries no instruction sentence, and the icon is a vial.

6. **Give Progress and Packs the world.** `qa/02-progress.png` is the weakest screen: replace
   `StatTile` (`StreakView.swift:89`) and its three identical tiles with one hero — the streak
   number at `.brandDisplay(size: 110)` standing in the pool with the longest run and days
   played as small type beneath it — and redraw the calendar as filled tide-pool dots on the
   canvas rather than blue rounded squares on white. In `PacksView`, the 1–240 grid of solid
   accent squares (`PacksView.swift:129`) becomes vials that are full when cleared and empty
   when not, so the ladder reads as a shelf. Both screens end with enough bottom padding that
   the last row is not sitting half-hidden under the tab bar the way "Share today's result"
   and level 6–10 are today. *Next capture:* neither screen has a white rounded card or a blue
   square on it.

7. **Design dark mode, and share an image.** `dark-01` through `dark-05` are the light
   screens with black substituted — same blue, same layout, no second voice. Give the dark
   palette its own canvas (deep water with a lantern glow, not `#000`), a lighter mint for
   type, and dimmer liquid so the tubes glow rather than blare. Then replace
   `ShareLink(item: shareLine)` at `StreakView.swift:33` with `ShareImage.render { … }` over
   `ShareLink(item:preview:)`: the rack of cleared vials, the day, the pours against par, the
   streak, on the brand canvas. *Next capture:* `dark-02-progress.png` is blue-black with a
   glow, and a rendered share card exists.

## Against the mocks

- **`design/mock-1-play.png` → `qa/01-play.png`.** The mock is a dusk tide pool: a dark
  gradient canvas, glass vials with specular highlights and colored light inside them, kelp
  fronds under the finished tubes, a serif "7" over a progress rail labelled POURED / THE LINE
  · 13, a hand-lettered "the charted line" arc, and buttons reading Back / Show me / Refill.
  The build is a gray sheet of paper with flat crayon rectangles, `4 moves  par 12` at
  headline size, a blue hint sentence, and Undo / Hint / Restart. Every single element of the
  mock is flatter in the build; the canvas, the glass, the kelp, the display numeral and the
  rail are absent entirely.
- **`design/mock-2-win.png` → the `.medium` sheet.** The mock is full screen: a sun on the
  horizon, "13" set huge in New York inside a thin ring over POURS, "You found the shortest
  line.", a start-to-the-line rail, the six cleared vials standing in the pool with fronds
  under each, then "Take the next one" / "Pour it again" / "Share the rack". The build is a
  half-height sheet with a 48 pt checkmark seal, "Level cleared", "18 moves" and "Next level".
  This is the largest gap in the app.
- **`design/mock-3-first.png` → onboarding.** The mock is a warm sand-to-sea wash with a drawn
  illustration of three vials being decanted at the shoreline, under "Every light wants its
  own glass." in a serif display face. The build is `drop.fill` over "Pour until the colors
  separate" on the kit's default background, and adds a third page that recites the pricing
  model.
- **`design/icon.svg` → the shipped icon.** The drawn icon — a lit vial standing in a ringed
  pool, being poured into from off-frame — is in `design/icon-1024.png` and was not shipped;
  the binary carries three flat rectangles on a navy gradient.
