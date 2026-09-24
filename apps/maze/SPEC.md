# Lacework

Planned 2026-09-24 from issue #8. Full plan with evidence is private in appmonkey
`plans/maze/PLAN.md`; this is the compression `app-build` reads.
Every revenue figure is modeled, not reported sales.

## Promise

One maze a day, the same one for everyone: draw a single unbroken line that fills every cell,
untimed, offline, and never an ad. For people who like a quiet daily puzzle and have deleted maze
games because the "no ads" promise was a lie.

## Wedge

From 100 sampled reviews of each of the top five maze apps (evidence 2026-09-24):

1. **They lie about being ad-free.** Three of the five are accused of it in their own reviews.
   "If you downloaded this game because it promised no ads - you were lied to." (Color Maze
   Master); "Don't believe the ad when it says no annoying ad's. After about the tenth level ad's
   start showing up." (Color Maze). One reviewer asks outright for our product: "The game is fun
   and I would give it 5 stars if they would add an option to remove ads." → **No advertising SDK
   in the binary.** `app-compliance` fails the build if one appears, so the claim is enforced by
   the pipeline.
2. **Progress is not safe.** "My progress keeps resetting. Twice now I've got to level 70 ish and
   then open the app again and I'm at level 1." (Color Fill 3D); "The daily maze has reset it self
   back to the beginning at least 3 times today!" (Color Maze). → Local-first persistence, the
   daily derived deterministically from the date, a solved maze stays solved.
3. **Rewards gated behind ad-watching.** "now watch 10 ads and two more levels to overcome"
   (Maze Madness); "after one level/round you get hit with an ad" (Tomb of the Mask). → No
   currency, no lives, no energy, nothing to watch.

Match what they love: **relaxing** and **challenging** are the top praise themes in four of the
five — untimed and quiet, but genuinely hard at depth ("I don't like all these easy levels when
you promise harder puzzles", Color Maze Master). And a **daily** board, which Color Maze proves
people want and fails to keep working.

## MVP

Three screens, one loop: open, solve today's maze, watch the streak grow, come back tomorrow.

1. **Today** — the day's board, derived deterministically from the date so everyone gets the same
   one. A grid with walls and one start cell; drag to extend a single continuous line through
   orthogonally adjacent open cells, each visited exactly once. Dragging back onto the line undoes
   it. Untimed, no score, no hints to buy. Solved when every open cell is on the line; the finished
   figure is drawn and the day is marked. Re-opening a solved day shows the finished lace.
2. **Progress** — current streak, the month as a calendar of solved days, largest board solved,
   share as a plain text line. Daily local-notification toggle.
3. **Packs (Pro)** — graded packs from 8×8 to 14×14, plus an endless mode that never repeats a
   board. Per-size solve stats.

Plus the kit's Settings (restore, rate, share, support, privacy) and the paywall stating the
promise: no ads ever, nothing to run out of.

**The generator is the build.** Seed a Hamiltonian path over the open cells, then derive walls from
it; the solver must prove the board has **exactly one** solution before it is served, and a board
it cannot prove is discarded. No guessing is ever required. This is the same solver-first
discipline as Crosshatch's plate generator. A 14×14 board must rule in well under a second on the
simulator; if it does not, generate the packs at build time into a bundled JSON file.

Local-first: `@AppStorage` for streak and settings, SwiftData for solved boards. No network at all.

## Monetization

**One-time unlock, $4.99.** StoreKit 2. Product id `com.factory.maze.pro`.
Not a subscription, so guideline 3.1.2's Terms-of-Use block does not apply.
Pro unlocks the graded packs, endless mode and per-size stats. The daily maze and the first pack
of 60 boards stay free forever, with no ads.

## Needs from the owner

- [ ] Nothing for the build. No API, no key, no account, no network.
- [ ] A real-iPhone test (haptics, the daily notification, the share sheet) before submit.
- [ ] Create the app record in App Store Connect and answer App Privacy ("we do not collect data").

## Store

- Name: `Lacework: One-Line Maze Puzzle` (30)
- Subtitle: `One-line maze. No ads, ever.` (28)
- Keywords: maze, one line puzzle, path puzzle, ad free game, daily maze, relaxing puzzle, brain teaser, one stroke, offline puzzle, logic
- Primary category: Games (Puzzle). Secondary: Games (Casual).
- Name check 2026-09-24: **App Store collision not checked** — the planning sandbox has no App
  Store search and no browser. "Lacework" appears in none of the 20 apps in the evidence set;
  "Warren" and "Bobbin" were the other candidates and are also clear of it.

## Distinct from the leader

Not a reskin. Tomb of the Mask is a real-time arcade game — its own description says "traps,
enemies, game mechanics and power-ups" — sold on weekly and yearly subscriptions. Lacework is
turn-based, untimed, single player, offline, with no currency and no subscription. Color Fill 3D
is the nearest mechanic (fill every cell) and differs on every other axis: 3D cube navigation,
ad-funded, and the subject of scareware reports in its own reviews. The daily shared board, the
uniqueness proof and the lace identity exist in none of the five.

## Day-7 bar

100 downloads, 3 paying, rating at or above 4.5. The niche median is $6K/mo modeled — below the
niches the factory has shipped into — so the bar stays at the default rather than rising. The
four-week kill rule and the daily metric are in the plan, §11.

## Risks

- **App Review 4.3 is the main risk and it is high.** Maze is among the most cloned mechanics on
  the store and Color Fill 3D already ships a fill-every-cell game. Answered by the
  uniqueness-proved generator, the daily shared board, the lace identity and no ad SDK. The first
  screenshot must show the daily and the streak, never a bare grid.
- The niche is smaller and more concentrated than this morning's board suggested: $9.6M/mo modeled
  across 42 apps, top app 46%, median $6K/mo. If the day-7 bar misses, the kill rule applies.
- Everything here is copyable in a week except the honesty, which an ad-funded incumbent cannot
  copy without losing its revenue.
- Licensed content, regulated claims, hardware, backend, network effects: none. Game flag: keep it
  to the one mechanic above — no real-time action, no 3D, no economy, no multiplayer.
