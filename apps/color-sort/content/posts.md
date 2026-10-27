# Tidepour, posts

Links: the landing page (published from `content/site/`) and, once approved, the App Store
page. Until the app has an id, posts that need a link use the landing page. Images are the
composed store screenshots in `store/screenshots/en-US/` unless a post says otherwise; clips
are in `content/clips/` (see `videos.md`).

The voice is the keeper of the pool's, turned outward: calm, short, concrete. It talks about
glass, light and lines, and about what the app does — never about the reader. No
"game-changer", no "you're going to love", no emoji confetti. The complaints quoted below are
real App Store reviews of the category's leaders (from SPEC.md's evidence, 11 Sep 2026); name
the review, never the competitor, in anything we post.

## X — ten posts

1. **One-liner, the wedge.**
   Every board in Tidepour is solved before you see it. If the solver can't finish it, the
   board is thrown away and dealt again. You can't be handed a dead end.
   *(image: 02, "Every level has a solution")*

2. **One-liner, from the reviews.**
   "It will generate levels that are impossible and the ads are relentless." — a color sort
   review.
   Tidepour has neither. Every rack is solved before it's dealt, and there's no ad SDK in it.
   *(image: 02)*

3. **One-liner.**
   Things Tidepour does not have: ads, coins, lives, a timer, an extra tube to buy, an
   account, a network connection.
   *(image: 04, "No ads. No coins. No lives.")*

4. **Thread opener.**
   Every color sort game on the App Store is the same picture: crayon tubes on white, a coin
   counter, a TV-shaped "watch to skip" button.
   I made one that's glass vials of light in a tide pool at dusk.
   - 2/ Same rule you know: pour the top colour into a tube where it matches and there's
     room, until each tube holds one colour.
   - 3/ The difference is underneath. Every board is dealt on the phone and searched to the
     end. A board with no way out is thrown away. Nothing you're given is unwinnable.
   - 4/ The search is breadth-first, so the move count it finds is the shortest there is.
     That's par: a rail across the top that fills as you pour. Beat it and the win is louder.
   - 5/ "Show me" points at the next pour of that line. Leave the line and it re-solves from
     the board in front of you, so the hint is never stale.
   - 6/ One shared rack a day, from the date. A streak. No ads, no coins, no timer. 60 racks
     and the daily free forever; $4.99 once for the rest. Not a subscription. [link]
   *(image on 1/: 07, the first screen. On 4/: clip 02.)*

5. **Before / after.**
   Before: "You start a round, ads. You restart a round, ads."
   After: you restart a round. That's it. It restarts.
   *(clip: 01, the pour)*

6. **One-liner, the pour.**
   The only verb in the game, three hundred times an evening, so it had better be good: the
   vial lifts, tips toward its glass, an arc of light pours across, the level overshoots and
   settles. The last unit is the top note.
   *(clip: 01, the pour)*

7. **One-liner, accessibility.**
   If you can't tell two of the colours apart, turn on the colour-blind palette: Okabe–Ito
   colours, and a different shape stamped on every unit, so the rack reads with no colour at
   all. VoiceOver reads every vial bottom-up.
   *(image: 05, "A shape on every color")*

8. **One-liner, the price.**
   "The price for ad free is outrageous." — a sort-game review.
   Tidepour's price for ad free is $0, because there are no ads. $4.99 once buys more racks,
   calm mode and the colour-blind palette. That's the whole shop.
   *(image: 06, "Pay once, or play free")*

9. **One-liner, saving.**
   Every pour is written to disk the moment you make it. Kill the app, crash it, let the
   battery die: you come back to the exact rack you left. Nobody here loses 400 levels.

10. **Launch-day post.**
    Tidepour is out. A color sort puzzle where every rack is solved before it reaches you: no
    ads, no coins, no lives, no timer, fully offline, one shared puzzle a day. Free, with $4.99
    once for the whole shore. [App Store link]
    *(image: 01, the win)*

## Reddit

Read each subreddit's sidebar and pinned rules on the day; they change. Post from an account
with real history in the sub, say you are the developer, answer every comment, and never
cross-post the same text.

### r/iOSGaming

Developer posts are allowed when they say so and are about the game. Flair it as the sub asks
for new releases.

**Title:** I made a color sort puzzle where every level is solved before you see it — no ads,
no coins, no lives

**Body:**
I'm the developer. Tidepour is a water-sort / color sort puzzle: pour the top colour from one
tube into another until every tube holds a single colour. You know the genre.

I read a few hundred reviews of the top five before building it, and they're four-and-a-half
stars with mostly angry reviews, all saying one of three things: levels that can't be won,
an ad after every round, and coins you need to buy to get past a hard one. So:

- **Every board is solved before it's served.** The app deals a board, runs a breadth-first
  search over it, and throws the board away if there's no way out. Nothing you're handed is a
  dead end.
- **Par is the solver's shortest line**, shown as a rail that fills as you pour. Going over
  costs nothing but the louder win.
- **The hint** steps through that verified line, and re-solves from wherever you are if
  you've wandered off it.
- **No ad SDK in it at all.** No coins, no lives, no timer, no extra tube to buy.
- One shared puzzle a day, from the date, and a streak. Fully offline, no account, nothing
  collected. Every pour is saved, so a crash never costs a level.
- A colour-blind palette with a shape on every unit.

The daily and the first 60 racks are free forever. $4.99 once opens the rest of the ladder,
calm mode and the colour-blind palette. Not a subscription.

It also looks nothing like the others — glass vials of light in a tide pool at dusk instead of
crayon tubes on white — but you can judge that from the pictures.

Happy to answer anything about the solver; keeping the deep boards provably optimal was most
of the work.

[App Store link]

### r/iosapps

Self-promotion by developers is allowed in the format the sub pins; use it.

**Title:** [Dev] Tidepour — color sort puzzle, no ads, every level checked solvable before
you see it

**Body:** the r/iOSGaming body cut to the bullet list and the price line, with the link.

### r/colorblind

A community for colour-blind people, not an app board. **No link and no app name in the
title.** Only post if the pinned rules allow a developer asking for feedback; if they don't,
skip it.

**Title:** Developer asking: does a shape on every colour make sorting puzzles playable for
you?

**Body:**
I make a colour-sorting puzzle (the "pour the liquids until each tube is one colour" kind).
The whole genre is unplayable for a lot of colour-blind people, and the usual fix is a
slightly different palette.

What I've done instead: the Okabe–Ito palette, plus a different shape stamped on every unit of
colour, so a tube reads as "circle, circle, triangle, square" and colour never has to carry
the meaning alone.

*(image: 05, cropped to the board, no caption)*

Does that read for you? Is there a shape set that works better, or a combination of colours in
that screenshot that still collapses? I'll change it based on what people here say.

If someone asks what it is, answer in a comment with the name and link.

### Not posted: r/puzzles

Considered and left out. It is a sub for puzzles to solve, and a sort board is not a puzzle
you can work on a still image the way a grid can be.

## Product Hunt

**Name:** Tidepour

**Tagline (≤60):** Color sort where every level is solved before you see it *(57)*

**Description:**
Tidepour is a color sort puzzle set in a tide pool at dusk: pour light from one glass vial to
the next until every vial holds a single colour. Every board is generated on the phone and
solved before it's dealt — a board with no way out is thrown away — and the solver's shortest
line becomes par. One shared puzzle a day, a streak, and a colour-blind palette with a shape on
every colour. No ads, no coins, no lives, no timer, no account, and no network connection.
Free, with a one-time $4.99 unlock for the rest of the ladder.

**First comment (maker):**
The top five color sort games all rate between 4.7 and 4.8 stars, and in a few hundred of
their reviews more than half were negative. The same three complaints, over and over: "it
gave me a level that can't be solved", "an ad every round", "you can't win without buying
coins".

Tidepour answers the first with a solver. Every board is dealt, searched breadth-first, and
discarded if it can't be finished, so the move count it finds is provably the shortest — that
number is par, and the hint walks you down it. The other two are answered by leaving things
out: there is no ad SDK, no currency, no lives and no timer to sell you out of.

The look came from the same place. Every competitor is crayon tubes on white paper. This one is
light in glass, standing in water.

I'd love to hear where the ladder feels too flat or too steep.

## Launch email

**Subject:** Tidepour is out: every level solvable, no ads

**Preview text:** A color sort puzzle at the blue hour.

Hi,

Tidepour is on the App Store today.

It's a color sort puzzle: pour light from one glass vial into the next until every vial holds
one colour. Underneath, it does one thing no other one does.

- **Every level has a solution.** Each board is solved on your phone before you see it; one
  with no way out is thrown away. The shortest line becomes par, and "Show me" walks you down
  it.
- **No ads. No coins. No lives. No timer.** Nothing here runs out, and nothing is for sale
  but more racks.
- **The same pool for everyone**, a new shared puzzle every day, offline.

The daily and the first sixty racks are free for good. $4.99, once, opens the rest of the
shore, calm mode and the colour-blind palette.

[Get Tidepour on the App Store]

The tide's out. Today's rack is on the flat.

— Starhive Concept

## Press blurb

**Tidepour** (iPhone, free with a one-time $4.99 unlock) is a color sort puzzle styled as glass
vials of light in a tide pool at dusk. Every board is generated on the device and solved by a
breadth-first search before it is served; boards with no solution are discarded, and the
shortest solution becomes the level's par and powers the hint. It carries no advertising SDK,
has no lives, timer or in-game currency, makes no network connection and collects no data. A
shared daily puzzle is seeded from the date. An optional colour-blind mode pairs the Okabe–Ito
palette with a distinct shape on every unit. By Starhive Concept. Privacy:
https://starhiveconcept.com/color-sort-privacy-policy-terms/
