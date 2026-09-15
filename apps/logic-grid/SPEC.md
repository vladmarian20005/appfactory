# Crosshatch

Planned 2026-09-15 from [issue #6](https://github.com/vladmarian20005/appfactory/issues/6) by the
build-request procedure. Full plan with evidence is private, in appmonkey
`plans/logic-grid/PLAN.md`; this is the compression `app-build` reads. All revenue figures are
**modeled**.

## Promise

One logic grid a day, solvable by pure deduction and proved before it is served. No ads, no timer,
no score, nothing that runs out. For people who like the "who owns the zebra" kind of puzzle and
have deleted puzzle games over ads that last longer than the game.

## Wedge

From the leader's last 50 reviews (29 at 3★ or under, scout 2026-09-15). Apple's review feed
returned nothing for all five top apps in the evidence run of the same morning
(`feedEmpty: true` on Woodoku, Crossmath, Nonogram.com, Redirect It! and That's My Seat), so
these three quotes are the leader's and there are no others:

1. **Ads that outlast the game.** "I used to love playing this game, especially during flights.
   Unfortunately, the ads have become overly excessive and lasts forever. I am about to
   uninstall." (Woodoku) → **No ad SDK in the binary.** The paywall says so and compliance checks
   the claim against the build.
2. **No way to buy your way out.** "Because you can't purchase the game to remove ads, and the ads
   don't make it easy to simply exit, next or wait them out: kids shouldn't play." (Woodoku) →
   **One one-time unlock.** The free tier is a real game, not a demo.
3. **A game that feels rigged.** "Soon as you set your high score off they think it's too high you
   will never beat it. Because they make sure you don't get nothing you need including sending you
   double pieces they now don't fit. Waste of time." (Woodoku) → **Every puzzle is verified
   uniquely solvable by pure deduction before it is served**, and the hint proves it by naming the
   clue that forces the next mark. Nothing is random, nothing is tuned against the player.

Match what works, from the top five's positioning rather than praise quotes (the evidence has
none): the **calm, unstressed framing** that is carrying the newest money in the niche — Redirect
It! sells itself as "minimalistic and relaxing, not cluttered and stressful" — and **depth that
does not run out**, which is where That's My Seat's hand-authored thousand levels stop.

Deliberately skipped: **the timer and the score chase.** Woodoku's whole complaint set grows out
of a high-score economy. Ship no score at all.

## MVP

Three screens, one loop: open, solve today's grid, keep the streak, come back tomorrow.

1. **Play** — the logic grid. A cast of three to five categories (people, pets, houses, times)
   across a cross-referenced matrix, the clue list below it, tap a cell to cycle ✓ / ✗ / blank.
   Certain cross-outs propagate automatically so bookkeeping never becomes the puzzle. Undo,
   restart, and a hint that names the clue forcing the next mark and why. No timer, no lives, no
   ads, no currency. State saved on every mark, so a crash never costs a puzzle.
2. **Progress** — today's puzzle seeded from the date so everyone gets the same grid; current
   streak; a month calendar of solved days; total solved; a plain-text share line that spoils
   nothing.
3. **Packs (unlock)** — the full generated ladder past the free 40, sized 3×4 up to 5×6, plus calm
   mode (muted palette, no move count) and a toggle for the auto-cross assist.

Plus the kit's Settings (restore, rate, share, support, privacy) and the paywall.

**Puzzles are generated, not a content pack.** Seeded random assignment → emit candidate clues
(direct, negative, relational, positional) → constraint solver → prune clues while the solution
stays unique → stop when removing any further clue makes it ambiguous. The solver's deduction
depth is the difficulty rating, so the ladder is measured rather than guessed. A puzzle that
cannot be proved unique is discarded, never served. If proving uniqueness on device is too slow,
generate the ladder at build time into a bundled pack — the guarantee is what matters, not where
it runs.

Local-first and fully offline: `@AppStorage` for streak and settings, SwiftData for solved
results. **No network call anywhere in the app.** Board drawn in SwiftUI with standard components
so the iOS 26 SDK applies Liquid Glass; no re-implemented controls.

## Monetization

**One non-consumable unlock, $4.99**, StoreKit 2. Product id
`com.starhiveconcept.logicgrid.unlock`. No subscription and no trial — 40 free puzzles plus a
free daily forever are the trial. Restore in Settings.

Free forever: the daily puzzle, the first 40 puzzles, streak, calendar, share, undo, restart,
hints. Unlock buys: the full generated ladder, calm mode, and the assist toggle.

All five competitors are free with ads and IAP, so there is no competitor price to match — the
reference point is the reviewer who could not buy their way out of the ads at any price.

## Needs from the owner

- [ ] Nothing for the build. No API, no key, no account, no network.
- [ ] Thursday: a real-iPhone test (haptics, share sheet, a sandbox purchase), then the submit
      approval.
- [ ] For upload: the existing App Store Connect API key and Team ID.

## Store

- Name: `Crosshatch: Logic Puzzles` (25)
- Subtitle: `One daily deduction puzzle` (26)
- Keywords: logic grid puzzle, deduction game, daily logic puzzle, brain teaser, clue puzzle, no
  ads puzzle, offline puzzle, zebra puzzle, einstein riddle, solve by logic
- Primary category: Games (Puzzle). Secondary: Games (Board).
- Name check 2026-09-15: **App Store collision not checked** — this sandbox has no App Store
  search. "Crosshatch" appears nowhere in the evidence; *Logic Grid Puzzles*, *Logic Daily: Grid
  Puzzles*, *Clue Master* and *Cross Logic* are live in the niche and were avoided. Deducto and
  Seven Clues were the other candidates.

## Distinct from the leader

Not a reskin. Woodoku is an endless block-dropper with a high-score economy, ads and IAP; its
"logic" is spatial packing, not deduction. Crosshatch has no score, no timer, no ads, no
currency, and a solve that is provable rather than lucky. The nearest real comparison, That's My
Seat, is a hand-authored pack of themed levels that will run out; ours is generated and proved.

## Day-7 bar

100 downloads, 3 paying, rating at or above 4.5. The niche median is $20K/mo modeled, so the bar
stays at the default. Four-week kill rule and the daily metric are in the private PLAN.md §11.

## Risks

- App Review 4.3: logic-grid puzzles are a template genre with live clones. Answered by the
  proved-unique generator, the shared daily grid, and a look decided in DESIGN.md before any
  Swift. The first screenshot shows the calendar and streak, not a bare grid.
- The generator is also the schedule risk: if uniqueness cannot be proved cheaply on device, the
  ladder is generated at build time into a bundled pack. No puzzle ships unproved either way.
- Copyable in a week by anyone willing to write the solver. The defensible part is the absence of
  ads and the calm, not the mechanic.
- Licensed content, regulated claims, hardware, backend, network: none. Game flag: the simple
  kind — one mechanic, single player, generated levels, no ads, no lives, no currency.
