# Lacework, posts

Links: the landing page (published from `content/site/`) and, once approved, the App Store
page. Until the app has an id, posts that need a link use the landing page. Images are the
composed store screenshots in `content/site/shots/` unless a post says otherwise.

The voice is the app's: plain, dry, specific. It talks about the piece and never about the
reader. No "game-changer", no emoji confetti, no "you're going to love".

## X — ten posts

1. **One-liner.**
   A maze game with no ad SDK in it. Not "fewer ads". None. There is nothing to switch on at
   level ten.
   *(image: 04, "No ads. Ever.")*

2. **One-liner.**
   One thread through every pin. It never crosses itself, and it never has to. Then the pins
   come out and the lace lifts off.
   *(image: 02, the lift)*

3. **One-liner.**
   Every maze in Lacework is proved by a solver to have exactly one answer before you see it.
   You get there by looking, not by guessing.

4. **One-liner.**
   Things Lacework does not have: lives, a timer, coins, a hint to buy, an ad, an account, a
   network connection.

5. **Thread opener.**
   Four of the top five maze games on the App Store are the same screenshot: neon arrows on
   black, three hearts, "Lv. 270", a lightbulb with a badge.
   So I built one that is linen, parchment and one indigo thread.
   - 2/ The rule: draw one unbroken line through every pin on the card. Every pin once, never
     crossing. It's a one-line maze, like Color Fill, but on a lacemaker's pillow.
   - 3/ Every board is generated on the phone and a solver proves it has exactly one answer.
     A board it can't prove is thrown away.
   - 4/ One pattern a day, from the date, the same for everyone. It runs a week like a
     crossword: 5×5 Monday, 14×14 with a hole cut in it Sunday.
   - 5/ Finished pieces go into a sampler you keep. It lives on your phone and doesn't reset.
   - 6/ No ads, no lives, no timer. Today's pattern is free forever. $4.99 once opens the
     whole book. Not a subscription. [link]

6. **Before / after.**
   Before: "RELAX YOUR BRAIN!" in a sticker, three hearts, an ad every level.
   After: a card pinned to a pillow, a thread, and a lacemaker who says "Not a knot in it."
   *(image: a neon-maze-style screenshot is not ours to post — use 03 alone and let the text
   carry the before)*

7. **One-liner, from the reviews.**
   "Twice now I've got to level 70 and then I'm at level 1." — a maze game review.
   Lacework keeps every piece you finish, on your phone, in a sampler that never resets.
   *(image: 01, the sampler)*

8. **One-liner.**
   Go wrong? Pick the thread out. It's free, as often as you like. The only thing it costs is
   that tonight's piece wasn't worked clean.

9. **One-liner.**
   Monday's pattern is five pins a side. Sunday's is fourteen, with a window cut in it, and
   only the start pinned. Same one for everybody. Today's is pricked.

10. **Launch-day post.**
   Lacework is out. A one-line maze on a lacemaker's pillow: one pattern a day, every board
   proved to have one answer, no ads, no lives, no timer, fully offline. Free, with $4.99
   once for the whole book. [App Store link]
   *(image: 02, the lift)*

## Reddit

Read each subreddit's sidebar and pinned rules on the day; they change. Post from an account
with real history in the sub, answer every comment, and never cross-post the same text.

### r/iOSGaming

Developer posts are expected to say so and to be about the game, not the pitch. Flair it as
the sub asks for new releases.

**Title:** I made a one-line maze with no ads, no lives and no timer, where every board is
proved to have one answer

**Body:**
I'm the developer. Lacework is a one-line maze (draw a single unbroken line through every
cell, never crossing) dressed as bobbin lace: the board is a pricking card pinned to a pillow,
the line is a thread, and when you finish, the pins come out and the piece lifts off into a
sampler.

What's different from the ones you've probably deleted:

- There's no ad SDK in it at all. Nothing to show up at level ten.
- Every board is generated on the phone and a solver proves it has exactly one solution
  before it's served. No guessing is ever required.
- One daily pattern from the date, the same for everyone. Easy Monday, 14×14 with holes cut
  in it by Sunday.
- No lives, no timer, no hints to buy. Undoing is free; it just means that piece wasn't
  "worked clean".
- Offline, no account, nothing collected.

Today's pattern and the first 60 in the book are free. $4.99 once opens the rest and an
endless mode. Not a subscription.

Happy to answer anything about the generator; making it prove uniqueness fast enough on a
14×14 board was most of the work.

[App Store link]

### r/iosapps

Self-promotion is allowed for developers in the format the sub pins; use it.

**Title:** [Dev] Lacework: a daily one-line maze, no ads, every board proved to have one answer

**Body:** the r/iOSGaming body, cut to the bullet list and the price line, with the link.

### r/puzzles

This is a sub for puzzles, not for apps. **No link, no app name in the title.** Post a
puzzle; mention the app only if someone asks where it came from.

**Title:** One thread through every pin: 7×7, exactly one answer

**Body:**
Draw one unbroken line that visits every dot exactly once, moving only up, down, left or
right, never crossing a wall and never crossing itself. It starts at the brass dot and ends
at the ringed one. There is exactly one solution.

*(image: a fresh 7×7 card with no thread on it, captured from the app with
`-rung 26 -board book -fresh`, cropped to the card. Put the solution in a spoiler comment.)*

### Not posted: r/Lacemaking

Considered and left out. It is a craft community, and a phone game that borrows the craft's
words is not what it is for. If a lacemaker finds the app and posts it there, answer
questions; don't start the thread.

## Product Hunt

**Name:** Lacework

**Tagline (≤60):** A one-line maze a day. No ads, ever. One answer, always. *(56)*

**Description:**
Lacework is a one-line maze puzzle worked on a lacemaker's pillow. Wind a single thread
through every pin on the card, never crossing, and when the last pin goes in the lace lifts
off into your sampler. One pattern a day, the same for everyone. Every board is proved by a
solver to have exactly one answer before you see it. No ads, no lives, no timer, no account,
and no network connection at all. Free, with a one-time $4.99 unlock for the whole pattern
book.

**First comment (maker):**
I read a few hundred reviews of the top maze games before building this. The same three
complaints came up over and over: the "no ads" promise turned out to be a lie around level
ten, progress reset to level one, and you had to watch ads to keep playing.

So Lacework has no ad SDK in it, keeps everything on your phone, and has nothing that runs
out. The part I'm proudest of is the generator: it lays a path through every pin, builds the
walls from it, then removes walls one at a time only while a solver can still prove there's
exactly one way through. That means even the hardest boards — fourteen a side, holes cut in
them, no end pinned — can be solved by reading, never by trial and error.

The lace look came from the same place. Four of the five leaders are neon on black. This one
is linen and one thread.

I'd love to hear where the difficulty curve feels wrong.

## Launch email

**Subject:** Lacework is out: a maze a day, no ads

**Preview text:** One thread through every pin, and the lace lifts off.

Hi,

Lacework is on the App Store today.

It's a one-line maze: wind one thread through every pin on a card, never crossing, until
none is left bare. Then the pins come out and the piece lifts off into your sampler.

- **One pattern a day**, the same for everyone. Gentle on Monday, fourteen pins a side with a
  window cut in it by Sunday.
- **Every board has exactly one answer**, proved by a solver before you see it.
- **No ads, ever.** No lives, no timer, nothing to buy your way out of. It works offline and
  collects nothing.

Today's pattern is free every day, and so are the first sixty in the book. $4.99, once,
opens the rest.

[Get Lacework on the App Store]

Today's is pricked and pinned.

— Starhive Concept

## Press blurb

**Lacework** (iPhone, free with a one-time $4.99 unlock) is a daily one-line maze puzzle
styled as bobbin lace: players wind a single thread through every pin on a pricking card and
the finished piece lifts off into a personal sampler. Every board is generated on the device
and proved by a solver to have exactly one solution. It carries no advertising SDK, has no
lives, timer or in-game currency, makes no network connection, and collects no data. A new
pattern is published daily, the same for every player, graded across the week from 5×5 to
14×14. By Starhive Concept. Privacy: https://starhiveconcept.com/maze-privacy-policy-terms/
