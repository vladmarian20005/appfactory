# Thousand, five short videos

Five vertical clips, 1080×1920 at 30 fps, recorded from the Release build on an iPhone 17 Pro
Max simulator (iOS 26.5) and in `content/clips/`. They're silent: a CI simulator has no audio
device, so the ceramic tick, the climbing scale and the Castilian voice aren't in them. Add the
app's own sounds recorded from a phone, or none. Never a stock ukulele bed. Captions aren't
burned in; the timings below are for whoever cuts them. The phone is padded left and right with
the app's lime plaster `#EDE3D6`, so captions can sit in the bands above and below it.

Caption style: SF Pro Expanded semibold (the app's display face), ink Carbón `#2B211A` on the
plaster, 64–72 px. The one word that matters goes in cobalt `#1C5AA6`. Lower captions are small
tracked uppercase in SF at about 30 px, Sombra `#63564A`, like the marks on the bench. Never
amber for text on plaster (3.3:1). No emoji, no bouncing text, no flags.

**Where the hooks come from.** Apple's review feed returned nothing for any of the five leaders
(SPEC.md §Wedge), so there are no one-star quotes to lift. The hooks come from what the leaders
sell in their own store copy: a subscription, a streak, lives and gems, forty languages. Name
the habit, never the competitor, and never show a competitor's screen.

## Recording

```sh
tools/sim.sh build apps/language-drills/ios Thousand     # Release build into ios/.build
node apps/language-drills/content/record.mjs             # all five; or pass ids: … record.mjs 01 04
node apps/language-drills/content/record.mjs --reuse     # re-cut from content/raw/ without recording
node apps/language-drills/content/record.mjs --raw       # record only, to measure new cuts
xcrun swift apps/language-drills/content/frames.swift apps/language-drills/content/clips/01-the-turn.mp4 sheet.png 0 3 6 9 12
```

`record.mjs` installs the build fresh, launches each take with the flags below, records with
`simctl io recordVideo`, stops it with SIGINT, and hands the kept range of every take to
`vertical.swift`. The runner has no ffmpeg, so AVFoundation scales, pads, sets 30 fps and joins.
A cold launch here shows the home screen, then 3–9 s of white window, so every cut starts where
the app had drawn. The cuts were measured from contact sheets and are noted in `record.mjs`.

Under `-demo` the app slows its own turn and its reward for the camera (the runner's simulator
drops most frames of a 340 ms turn). So the clips show the turn and the win at about a third of
the speed they run in the hand. That reads well as video. Don't speed it up to "real" pace,
and don't claim in a caption that it is real-time.

| Clip | Length | Takes (launch flags) |
| --- | --- | --- |
| `01-the-turn.mp4` | 24.0 s | `-onboarded -sampleData -demo turn` |
| `02-the-wall-grows.mp4` | 16.2 s | `-onboarded -sampleData -demo win` |
| `03-no-streak.mp4` | 15.9 s | `-onboarded -sampleData -screen progress` · `-onboarded -sampleData -swept` |
| `04-bought-once.mp4` | 16.0 s | `-reset` · `-onboarded -sampleData -fakeProducts -screen paywall` |
| `05-the-first-tile.mp4` | 15.8 s | `-onboarded -reset` · `-onboarded -sampleData -screen wall` |

The swept-bench take is cut at 9.4 s because the system's "Enjoying Thousand?" rating prompt
rises over it just after; `-sampleData` counts as enough sessions to trip it.

---

## 1. "Turn it over. Say how it went."

Clip: `01-the-turn.mp4` (24.0 s). The signature interaction, five words in a row. For anyone
who has used a flashcard app and found it a white card on grey.

| Time | Beat | Shot | On-screen text |
| --- | --- | --- | --- |
| 0.0–2.0 | Hook | A cobalt glazed tile on the bench: **ayudar**. The course empty along the top, `EVERYDAY · 22 DUE`. | **Turn it over. Say how it went.** |
| 2.0–4.5 | The turn | The tile turns. Cream face, cobalt band, amber corners: **to help**, *¿Me puedes ayudar?* / Can you help me? The three grade chips rise. | `NOT YET · GOT IT · EASY` |
| 4.5–6.5 | It sets | *Got it*; the tile flies to the course and the first gap fills. **ganar** rises from the stack. | One tile in. |
| 6.5–13 | Again | ganar turns: **to win, to earn**, *Ganó el primer premio.* Got it. | Every word comes with a sentence it lives in. |
| 13–19 | Again | **cerrar** → **to close**, *Cierra la ventana, por favor.* It flies up. The course shows three set. | `21 DUE` |
| 19–24 | A new panel | The glaze changes to almagre: **la señora**, then **la abuela**, *the grandmother*. | Twelve panels. A thousand words. · `THOUSAND · COMING TO THE APP STORE` |

## 2. "Your progress bar is a wall."

Clip: `02-the-wall-grows.mp4` (16.2 s). The reward. For the people who share their progress.

| Time | Beat | Shot | On-screen text |
| --- | --- | --- | --- |
| 0.0–4.0 | Hook | The session is over. The hero number counts up in amber, 189 → 213, over `OF A THOUSAND · +24 SET TODAY`. The wall of twelve panels below. | **Your progress bar is a wall.** |
| 4.0–8.0 | The wall | 213 holds. "Two hundred in the wall." / "Good hands today." / "Every panel standing, none left bare." | Every word you keep is a tile in it. |
| 8.0–11 | A new hundred | A lustre sweep crosses the wall left to right and glaze-chip confetti falls. | Cross a hundred and the whole wall **lights**. |
| 11–16.2 | The close | The wall settles. **Back to the wall**, **Share the wall**. Confetti once more. | It only ever grows. · `THOUSAND · 1,000 SPANISH WORDS` |

## 3. "No streak. Miss a week. Nothing happens."

Clip: `03-no-streak.mp4` (15.9 s). For the streak-anxious: the people who have kept a flame
alive at 11:58 pm and resented it.

| Time | Beat | Shot | On-screen text |
| --- | --- | --- | --- |
| 0.0–3.0 | Hook | Progress: the hero counts up to **213** at 104 pt, `OF A THOUSAND`. | **No streak.** |
| 3.0–6.5 | What's there instead | The kiln shelf: **23** due today and **6** tomorrow as two stacks of tiles. | One number, and it can't go down. |
| 6.5–10 | The twelve panels | Mortar bars in the themes' glazes: Everyday 39 / 83, People & family 28 / 83… | No calendar. No flame. |
| 10–15.9 | When you're done | The swept bench: "The bench is swept." / "Fifty-four tiles are drying. Six are ready tomorrow." **See the wall.** | Done for the day. It **stops**. · `THOUSAND · NO STREAK, NO LIVES` |

## 4. "Spanish, bought once."

Clip: `04-bought-once.mp4` (16.0 s). The wedge, said plainly: every leader rents.

| Time | Beat | Shot | On-screen text |
| --- | --- | --- | --- |
| 0.0–3.0 | Hook | The first screen: a lime wall with a mosaic half laid, a starred cobalt tile over its gap. "A thousand words, one wall." | **Spanish, bought once.** |
| 3.0–6.5 | What it is | Same page: "The words you actually meet, in the order you meet them." | 1,000 words, in order of use. |
| 6.5–11 | The price | The paywall: the kept wall under its lamp, "The whole wall.", three lines: all 1,000 words; works in a tunnel; one payment, no subscription, ever. | `$9.99 · ONE TIME` |
| 11–16 | The terms | "The Whole Wall · $9.99 one time", **Open the whole wall**, Restore purchases. | No subscription. Nothing renews. · `FIRST 100 WORDS FREE` |

Hold the paywall until the end so the price line can be read. There are no renewal terms to
show because nothing renews; don't add a caption that implies a trial.

## 5. "Nobody tells you to tap it."

Clip: `05-the-first-tile.mp4` (15.8 s). The craft beat, for design people and r/iosapps:
the first tile teaches itself.

| Time | Beat | Shot | On-screen text |
| --- | --- | --- | --- |
| 0.0–0.8 | Hook | A first-ever bench: one cobalt tile, **el / la**, `EVERYDAY · 12 DUE`, nothing else on the screen. | **Nobody tells you to tap it.** |
| 0.8–2.0 | The peek | The tile tips to 14° and back, showing a sliver of its clay edge. | *(no text, let it move)* |
| 2.0–4.5 | Again | It peeks once more, then stops for good. | The tile shows you. |
| 4.5–7.8 | Still | The tile at rest. | No tutorial. No mascot. |
| 7.8–15.8 | The thousand | The Wall: Everyday 39 OF 83, glazed, half-glazed and raw-clay tiles at a 3 pt grout gap; People & family in almagre below. | This is all thousand. Every one has a place. · `THOUSAND · SPANISH VOCABULARY` |

---

## Where each one goes

| Clip | X | TikTok / Reels / Shorts | Product Hunt gallery |
| --- | --- | --- | --- |
| 1 | Post 2, thread 2/ | Launch day | Yes |
| 2 | Post 6 | Day 2 | Yes |
| 3 | Post 3 | Day 4 | No |
| 4 | Thread 4/ | Day 7 | Yes |
| 5 | Reserve | Day 9 | No |

On TikTok, Reels and Shorts the first frame is the hook, so the hook caption goes on from
frame 0. End every clip on `THOUSAND` and the App Store line. Until the app has a store page,
that line reads "Coming to the App Store", never a link. There's no link in the video: the link
goes in the bio or the post.
