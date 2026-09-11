# Tidepour

Planned 2026-09-11 from [issue #3](https://github.com/vladmarian20005/appfactory/issues/3) by the
build-request procedure. Full plan with evidence is private, in appmonkey `plans/color-sort/PLAN.md`;
this is the compression `app-build` reads. All revenue figures are **modeled**.

## Promise

A color-sort puzzle where every level is guaranteed solvable, there are no ads, and nothing runs out.
Pour the tubes until each color is separated, for a five-minute break — not a slot machine.

## Wedge

From 100 sampled reviews of each of the top five apps in the niche (evidence 2026-09-11; all five
rate 4.71–4.84★ while 55–83% of sampled reviews are negative):

1. **Levels that cannot be won.** "This app lowkey sucks. It will generate levels that are impossible
   and the ads are relentless." (Magic Sort!); "Some levels there isn't a possible solution without
   using the extra slot… Fix your game." (Nut Sort); "once you get to level 99 it's impossible to
   advance without paying" (Magic Sort!). → **The generator solves every level before it is served.**
   Unsolvable boards are discarded and regenerated; the solver's move count becomes the level's par,
   and a hint can replay the verified solution one move ahead.
2. **Ads, and an insulting price to escape them.** "the ads are too long, and there are way too many.
   Not enough game play time for the amount of ads. The price for ad free is outrageous." (Block
   Out!); "You start a round, ads. You restart a round, ads." (Nut Sort). → **No ad SDK in the
   binary.** The paywall says so and compliance checks the claim against the build.
3. **Coins and buyable progress.** "They want your money. You can't beat levels without buying coins"
   (Block Out!); the ad economy devalued mid-flight — "So what one ad used to buy, I now need four.
   I'm deleting the app." (Ball Sort). → **No currency, no consumables, no lives.** One one-time
   unlock, or play free forever.

Match what they love: the calm — "I'm very ill. This helps me focus on something other than the pain."
(Magic Sort!), "Super relaxing, and it makes you think." (Ball Sort) — and **full offline play**: "one
of the best calming games you could have u can play it in the car with no WiFi" (Nut Sort).

Deliberately skipped: **the timer** (Block Out!'s reviews name it directly), plus multiplayer,
accounts, shop and leaderboards.

## MVP

Three screens, one loop: open, pour today's puzzle, keep the streak, come back tomorrow.

1. **Play** — the board. Tubes of colored liquid; tap a source tube, tap a destination, it pours if
   the top colors match and there is room. Undo, restart, and a hint that steps the verified
   solution. No timer, no lives, no coins, no ads, no interstitials. State saved on every move, so a
   crash or a kill never costs a level — Water Sort's reviewers lose hundreds of levels to this.
2. **Progress** — the daily puzzle, seeded from the date so everyone gets the same board; current
   streak; a month calendar of days played; levels cleared; a plain-text share line. A Block Out!
   reviewer asked for exactly this: "you guys should add a daily challenge and a streak for every
   day".
3. **Packs (unlock)** — the full difficulty ladder past the free set, calm mode (no move counter,
   muted palette, slower pour), and color-blind-safe palettes with a shape marker on each unit. Water
   Sort shipped a glare update and got "It's hard to see colors" in return.

Plus the kit's Settings (restore, rate, share, support, privacy) and the paywall.

**Levels are generated, not a content pack.** Seeded generator → breadth-first solver over tube
states → keep only solved boards, store par. Difficulty comes from the solver's move count, not from
tube count alone: Water Sort's complaint is "At roughly level 100, they keep doing the same beginner
puzzle."

Local-first and fully offline: `@AppStorage` for streak and settings, SwiftData for level results.
**No network call anywhere in the app.** Board drawn in SwiftUI with standard components so the iOS 26
SDK applies Liquid Glass; no re-implemented controls.

## Monetization

**One non-consumable unlock, $4.99**, StoreKit 2. Product id `com.starhiveconcept.colorsort.unlock`.
No subscription and no trial — the 60 free levels plus a free daily puzzle forever are the trial.
Restore in Settings.

Free forever: the daily puzzle, the first 60 levels, streak, calendar, share, undo, restart, hints.
Unlock buys: the full generated ladder, calm mode, color-blind palettes and shape markers.

All five competitors are free with ads and consumables, so there is no competitor price to match —
the reference point is what their users say the escape costs.

## Needs from the owner

- [ ] Nothing for the build. No API, no key, no account, no network.
- [ ] Before the App Store Connect record: **search the App Store for the name** — see Store below.
- [ ] Later, on a phone: TestFlight pass (haptics, share sheet, a real sandbox purchase), then the
      submit approval.
- [ ] For upload: the App Store Connect record created by hand (Apple's API refuses `CREATE` on
      `apps`) and the one non-consumable IAP.

## Store

- Name: `Tidepour: Color Sort Puzzle` (27/30)
- Subtitle: `No ads. Every level solvable.` (29/30)
- Keywords: color sort, water sort puzzle, ball sort, relaxing puzzle, no ads game, daily puzzle,
  brain, calm, tubes, offline
- Primary category: Games (Puzzle). Secondary: Games (Board).
- Screenshot captions: "Every level has a solution. We check before you see it." / "The same puzzle
  for everyone, every day." / "No ads. No coins. Nothing runs out."
- **App Store collision not checked.** The planning sandbox has no route to Apple. `Tidepour` is none
  of the five apps in the evidence; alternates held in reserve are `Hueflask` and `Pourline`. Search
  before the record is created.

## Distinct from the leader

Not a reskin. Magic Sort! and Block Out! (both GRAND GAMES) are ad-and-coin economies whose revenue
comes from interstitials and consumable slots, and whose levels are, by their own reviewers' account,
sometimes unwinnable without paying. Tidepour has no ad SDK, no currency, no lives and no timer, and
its defining mechanic — a level no player can be handed unless the app has already solved it, with
the solution available as a hint — exists in none of the top five. The daily shared seed, the streak
calendar and the color-blind shape markers are also absent from all five.

## Day-7 bar

100 downloads, 3 paying, rating at or above 4.5. The niche median is $54K/mo modeled, above the
default assumption, so the bar stays at the default. Four-week kill rule and the daily metric are in
the private PLAN.md §11; the metric to watch is paid conversion rate, and under 1% means the thesis
is wrong, not the execution.

## Risks

- **Guideline 4.3, spam/reskin — the main gate.** 49 apps share roughly one mechanic. The answer must
  be visible in the first screenshot: the daily puzzle and streak, not a generic tube board. Backed by
  an original SwiftUI board, the solvability guarantee, accessibility markers, no ad SDK and a
  one-time price instead of a coins economy.
- **Distribution.** The niche grade is "Open field — demand is spread out. No single leader to
  dislodge, so distribution decides it." Nothing in a three-screen app fixes that.
- **Copyable in a week** — the solver is a few hundred lines. What is not copyable is a competitor
  giving up ad revenue.
- **Generator monotony** if difficulty is driven by tube count rather than solver move count.
- Licensed content, regulated claims, hardware, backend: none. Network: none, anywhere. Game flag:
  one rules-based mechanic, single player, generated levels, no ads, no lives, no currency — the
  shape Quizday already shipped.
