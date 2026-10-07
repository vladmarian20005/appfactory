# Quizday, five short videos

Five vertical clips, 1080×1920 at 30 fps, recorded from the shipped Release build on an
iPhone 17 Pro Max simulator (iOS 26.5) and in `content/clips/`. They're silent: a CI simulator
has no audio device, so the press's tones aren't in them. Add the app's own sounds or none.
Never add a stock "game show" bed. Captions aren't burned in. The timings below are for
whoever cuts them (CapCut, or ffmpeg's `drawtext` on a machine that has it). The phone is
padded with newsprint `#F5EFE2` left and right, so captions can sit in the bands above and
below it without covering the screen.

Caption style: New York (or Georgia) bold, ink `#1B2027` on the newsprint, 64–72 px. The one
word that matters goes in stamp red `#C1362C`. Lower captions go in SF Mono uppercase, tracked,
in `#5E6470`, like the app's datelines. No emoji, no bouncing text.

Hooks come from the leaders' one-star reviews (SPEC.md §Wedge). Name the complaint and don't
name the competitor. A competitor's screen never appears.

## Recording

```sh
tools/sim.sh build apps/quizday/ios Quizday     # Release build into apps/quizday/ios/.build
node apps/quizday/content/record.mjs            # all five; or pass ids: … record.mjs 01 04
node apps/quizday/content/record.mjs --reuse    # re-cut from content/raw/ without recording
xcrun swift apps/quizday/content/frames.swift apps/quizday/content/clips/01-the-ink-press.mp4 sheet.png 0 3 6 9 12
```

`record.mjs` launches each take with the flags below, records with `simctl io recordVideo`,
stops it with SIGINT, and hands the kept range of every take to `vertical.swift`. The runner
has no ffmpeg, so AVFoundation scales, pads, sets 30 fps and joins. A cold launch on a runner
shows the home screen and then 3–7 s of blank window, so each cut starts where the app had
drawn. The cuts were measured from contact sheets, and they're noted in `record.mjs`. If a
re-record looks different, run `record.mjs --raw` and measure again.

`-screen share` drew nothing in 17 s, so the shared front page appears as the result screen
it's made from, not as the 1080×1350 card itself.

| Clip | Length | Takes (launch flags) |
| --- | --- | --- |
| `01-the-ink-press.mp4` | 19.2 s | `-onboarded -reset -demo answer` |
| `02-the-edition-prints.mp4` | 21.0 s | `-onboarded -editions 19 -demo win` |
| `03-the-paper.mp4` | 21.0 s | `-reset` · `-onboarded -reset` · `-onboarded -sampleData -fakeProducts -screen paywall` |
| `04-the-late-edition.mp4` | 20.5 s | `-onboarded -editions 12 -screen late` · same plus `-lateStart` · `-onboarded -editions 19 -answered 8` |
| `05-the-file.mp4` | 19.2 s | `-onboarded -sampleData -screen scorecard` · `-onboarded -editions 19 -answered 8` |

---

## 1. "A wrong answer here costs no ad."

Clip: `01-the-ink-press.mp4` (19.2 s). From the complaint: *"Every time I get a question
wrong… I have to sit through a long ad."*

| Time | Beat | Shot | On-screen text |
| --- | --- | --- | --- |
| 0.0–2.5 | Hook | Question four, Sport: "What shape is a standard football (soccer) pitch?" Three squares inked, the run of three lozenges. | **A wrong answer here costs no ad.** |
| 2.5–5.5 | The question waits | Four ruled answer boxes, nothing pressed. | `NO TIMER · NO LIVES` |
| 5.5–8.5 | The press, right | D, Rectangle, inks proof green; "GOOD EAR." stamps over it; the footnote sets: "The laws set a rectangular field of play…", `SOURCE · FIFA LAWS OF THE GAME`. | Right: it **inks in**. |
| 8.5–10.9 | The page turns | Question five, Art & Literature, Medium: "Who painted The Starry Night?" | `Q5 OF 10` |
| 10.9–14 | The press, wrong | C, Claude Monet, pencilled out in graphite under "PENCIL IT OUT."; Vincent van Gogh circled in pencil; the tally square struck through; `RUN BROKEN`. | Wrong: **the reason prints.** |
| 14–19.2 | The point | The footnote holds: "Van Gogh painted it in 1889 from his room at the asylum in Saint-Rémy-de-Provence." `SOURCE · MUSEUM OF MODERN ART`. | No ad. Just the answer, and where it's from. · `QUIZDAY · FREE ON THE APP STORE` |

## 2. "Finish ten. It prints a front page."

Clip: `02-the-edition-prints.mp4` (21.0 s). The reward, for the people who share their
Wordle grid.

| Time | Beat | Shot | On-screen text |
| --- | --- | --- | --- |
| 0.0–2.8 | Hook | Question ten, Geography, Hard: "What is the capital of Canada?" Nine squares inked, one struck. | **Finish ten. It prints a front page.** |
| 2.8–5 | The last press | A, Ottawa, inks green; "NO CORRECTION NEEDED." stamps; "Print the edition" rises. | `Q10 OF 10` |
| 5–9.3 | The footnote | "Queen Victoria chose Ottawa as the capital in 1857, ahead of the larger cities." `SOURCE · GOVERNMENT OF CANADA` | Every answer has a source. |
| 9.3–11 | To press | The paper darkens, the masthead sets, the score counts up to 9 /10. | *(no text, let it print)* |
| 11–13 | The headline | "STOP THE PRESS" stamps in red; shredded newsprint falls; the ten squares print; "One got past you. One." | **STOP THE PRESS** |
| 13–21 | The front page | The brass ribbon, 20 days running; "Twenty filed. At twenty-five the late edition runs to eight."; the late edition box; Share the edition. | Share it. It doesn't give the answers away. · `QUIZDAY · A NEW EDITION EVERY MORNING` |

## 3. "No lives. No coins. Just the paper."

Clip: `03-the-paper.mp4` (21.0 s). From the complaint: *"I just don't like how EVERYTHING
costs gems, or coins."* and *"a total rip off to have to pay to get more lives."*

| Time | Beat | Shot | On-screen text |
| --- | --- | --- | --- |
| 0.0–3 | Hook | The first screen anyone sees: the QUIZDAY masthead over the drawn hand press, its flywheel turning. | **No lives. No coins. Just the paper.** |
| 3–8 | What it is | "One edition a day — Ten questions, dated and set fresh each morning." | One edition a day. |
| 8–15 | Today | Today's edition, unplayed: masthead, the dateline, the press, "Ten questions, set this morning.", today's sections, `4 EASY · 4 MEDIUM · 2 HARD`, Open today's edition. | Ten questions. About two minutes. · `NOTHING RUNS OUT` |
| 15–21 | The only price | The composing room: Pro's three bullets, "The daily edition stays free and always will — no ads, nothing to run out of.", weekly and yearly with a 3-day free trial. | The daily edition is **free**. Pro is optional practice. |

Keep the paywall on screen long enough to read the renewal line. A clip that shows a price
must not cut away from its terms.

## 4. "Some things you can't buy. You file them."

Clip: `04-the-late-edition.mp4` (20.5 s). The anti-pay-to-win beat: the one door money
doesn't open.

| Time | Beat | Shot | On-screen text |
| --- | --- | --- | --- |
| 0.0–3 | Hook | LATE EDITION masthead, `SET FROM YOUR OWN CORRECTIONS`, the spike of filed back issues. | **Some things you can't buy.** |
| 3–8 | What it is | "Five that got past you, pulled back off the spike." Sections: Sport, Geography, Music, Science. Pull the corrections. | The late edition: five of your own misses. |
| 8–13 | One of them | Late edition, Music: "Which instrument does a percussionist strike with mallets and has tuned metal bars?" | `LATE EDITION · MUSIC` |
| 13–20.5 | How you get it | The front page: 8 /10, STOP THE PRESS, 21 days running, "Twenty-one filed. At twenty-five the late edition runs to eight.", the late edition box. | Opens at seven editions filed. **Not for sale.** · `QUIZDAY` |

## 5. "Your streak, printed like back issues."

Clip: `05-the-file.mp4` (19.2 s). For the daily-ritual crowd: the calendar and the streak are
the reason to come back, not a timer or a nag.

| Time | Beat | Shot | On-screen text |
| --- | --- | --- | --- |
| 0.0–3 | Hook | THE FILE: 13 at 96 pt, the brass DAYS RUNNING ribbon. | **Your streak, printed like back issues.** |
| 3–9 | The month | The October calendar: played days in ink at three densities by score, today circled in red pencil; `BEST 13 · 19 EDITIONS FILED · 148 OF 190 ANSWERED`. | Every day you play, filed and dated. |
| 9–11 | Today's edition prints | The front page arrives: masthead, the score counting up to 8 /10, newsprint falling. | *(no text)* |
| 11–19.2 | The page | STOP THE PRESS, "Two slipped through. The rest are yours.", 21 days running, the countdown to tomorrow's edition. | Miss a day? The streak starts again. That's all. · `NO ADS · NO ACCOUNT · FREE` |

---

## Where each one goes

| Clip | X | TikTok / Reels / Shorts | Product Hunt gallery |
| --- | --- | --- | --- |
| 1 | Post 2, thread 3/ | Launch day | Yes |
| 2 | Post 8 | Day 2 | Yes |
| 3 | Reserve | Day 4 | No |
| 4 | Thread 6/ (or screenshot 04) | Day 7 | No |
| 5 | Reserve | Day 9 | No |

On TikTok, Reels and Shorts the first frame is the hook, so the hook caption goes on from
frame 0. End every clip on `QUIZDAY` and the App Store line. There's no link in the video:
the link is in the bio or the post.
