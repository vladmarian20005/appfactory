# Tallies, five short videos

Format: vertical 1080×1920, 30 fps, 20–30 seconds, captions burned in, no voice. The app's own
sound is the soundtrack: the `.step` tone climbing through a gate and resetting on the fifth,
the `.pop` of a gate closing, the `.fanfare` of a scored stave. Keep them in; a counter that
sounds like it is filling is something none of the leaders do.

Hooks come from the wedge in SPEC.md and the category as DESIGN.md §2 found it: a single number
on a beige screen with a banner ad, a "Remove Ads" row in Settings, a habit tracker that wants
an account before it will count to three, and three of five leaders drawing the same chrome
clicker with an odometer drum. They are paraphrases of what those apps are, not quotes from
anybody's review.

Captions: SF Pro Compressed Heavy, walnut `#221A0F` on an ash `#F0E5CC` strip with 5 px corners
and a 6 px keel-red `#A2361B` band down its left end — the stave, as a caption. The stencil caps
(SF Mono, tracked wide, uppercase) for any small label. Never white-on-black subtitles, never a
sticker, never an emoji.

End card for every video (last 3–4 s): the icon on the limewash `#C3B9A3`, **TALLIES** in
compressed heavy, "Count anything. No account.", and "Coming soon to the App Store" until there
is an id, "On the App Store" after.

## Recording

Raw footage was recorded on the runner's simulator (iPhone 17 Pro Max, iOS 26.5) on 7 Oct, by
`node apps/tallies/content/record.mjs`. Nothing on a runner can touch the screen, so every shot
is a launch flag that makes the app perform it (`ios/App/LaunchOptions.swift`). The `.mov` files
are in `content/raw/` and stay out of git; the run's artifact carries them.

**Not converted yet.** The runner had no ffmpeg, so the vertical MP4s are not cut. On any
machine that has it:

```sh
# vertical 1080×1920, 30 fps; the 6.9" capture is padded rather than stretched, on the limewash
for f in apps/tallies/content/raw/*.mov; do
  ffmpeg -y -i "$f" -vf "scale=-2:1920,pad=1080:1920:(ow-iw)/2:0:color=0xC3B9A3,fps=30" \
    -c:v libx264 -pix_fmt yuv420p -movflags +faststart \
    "apps/tallies/content/clips/$(basename "${f%.mov}").mp4"
done
```

The device capture is 1320×2868 (about 0.46:1), narrower than 9:16, so it scales to the full
1920 height and is padded to 1080 wide with the limewash colour — the letterbox reads as the
wall behind the bench, not as black bars. `content/clips/*.mp4` is committed once cut.

| Clip | Flags | Length | What is on it |
| --- | --- | --- | --- |
| `cut.mov` | `-onboarded -reset -sampleData -pro -demo cut` | 14 s | The face of *Pull-ups*. About 2 s in, five cuts land over ~3 s: the notch opens, swarf flies up and right, the blade walks, the gate closes; 534 → 538. Then still. |
| `score.mov` | `… -pro -demo score` | 16 s | The forty-eighth to the fiftieth cut, then the score: gates light left to right, the corner-to-corner stroke, the ghost count-up, the stave lifting into the rack, the date stamped, the chips. |
| `bench.mov` | `-onboarded -reset -sampleData` | 8 s | The bench: three staves laid across at their tilts, the uncut fourth blank, the rack at the foot. Still. |
| `ledger.mov` | `… -pro -screen ledger` | 8 s | The ledger: week and month per stave, then each day as a rule with its cuts notched where they landed. Still. |
| `day5.mov` | `… -pro -days 5 -screen face` | 7 s | A first week: a short stave, mostly empty strip, no rack. |
| `day500.mov` | `… -pro -days 500 -screen face` | 7 s | Half a year: strip cut to the hour, the bench oiled dark, a full rack. |
| `paywall.mov` | `… -fakeProducts -screen paywall` | 7 s | The rack and the ledger; "Three staves and a week of strip stay free". |
| `settings.mov` | `… -screen settings` | 6 s | On this bench: staves, notches cut, days kept. No account row, because there is no account. |

The cut and the score are the only clips with motion; every other shot is a still held under a
caption, which is how these read anyway. Where a beat below wants the cut for longer than its
3 s of action, loop that 3 s — five cuts and a gate closing reads the same the second time.

---

## 1. "One number. One banner ad."

The wedge, said plainly: most counter apps are a number on a plain screen with an ad under it.

| s | Shot | On-screen text |
| --- | --- | --- |
| 0–3 | **cut**, first frame, total 534 held | *One number. One banner ad.* |
| 3–8 | **cut**, the five cuts and the gate closing (2–5 s of the clip) | *This one cuts a notch instead.* |
| 8–13 | **bench** | *Three counters free. No ad SDK in it at all.* |
| 13–18 | **settings** | *Nothing to remove. Nothing to sign into.* |
| 18–22 | **cut**, looped, the gate closing | *Five to a gate.* |
| 22–26 | End card | *Tallies. Count anything. No account.* |

Captions in: 0.2 s, out: 0.2 s, no animation beyond a fade. The tone of each cut is audible
under 3–8 s; let it play.

## 2. "Why does a counter need my email?"

Against the habit trackers that want an account before they will count to three.

| s | Shot | On-screen text |
| --- | --- | --- |
| 0–3 | **bench**, still | *Why does a counter need my email?* |
| 3–9 | **cut**, five cuts | *It doesn't. Open it and cut.* |
| 9–14 | **settings** | *No account. No sync. No network at all.* |
| 14–20 | **ledger** | *The record stays on your phone.* |
| 20–24 | End card | |

## 3. "Fifty, and it's scored."

The reward, start to finish. This is the one most likely to be watched twice.

| s | Shot | On-screen text |
| --- | --- | --- |
| 0–3 | **score**, the first frame, the stave nearly full | *Fifty notches to a stave.* |
| 3–6 | **score**, the forty-eighth and forty-ninth cuts | *Forty-eight. Forty-nine.* |
| 6–14 | **score**, the fiftieth, the gates lighting, the stroke, the count-up, the lift into the rack, the date | (no text — let the score play) |
| 14–19 | **score**, the held final frame with the headline and sitting card | *Scored, dated, and stood in the rack.* |
| 19–23 | **day500**, the full rack | *It is still there in a year.* |
| 23–27 | End card | |

Do not caption over 6–14. The fanfare and the stamp are the hook.

## 4. "Took one too many?"

The wax: a correction recorded honestly. For the people who mis-tap a clicker and lose count.

| s | Shot | On-screen text |
| --- | --- | --- |
| 0–3 | **cut**, total held | *Tapped one too many?* |
| 3–8 | **cut**, five cuts | *Every tap is a notch in the wood.* |
| 8–14 | **cut**, held on the WAX stick at the stave's left end | *The wax stick takes the last one back.* |
| 14–19 | **ledger** | *The number is right. The wax still shows.* |
| 19–22 | **bench** | *An honest stave has a few.* |
| 22–26 | End card | |

There is no clip of a wax being pressed — no demo flag performs it. The beat at 8–14 holds on
the stick and lets the caption do the work. If a demo flag for the wax is added later, record it
and drop it in here.

## 5. "Every counter app is a chrome clicker."

Against the category's look: three of the five leaders draw the same brushed-steel hand tally
with an odometer drum.

| s | Shot | On-screen text |
| --- | --- | --- |
| 0–3 | **bench**, still | *Every counter app is a chrome clicker.* |
| 3–9 | **cut** | *This is a tally stick. You cut it.* |
| 9–13 | **day5** | *Day five.* |
| 13–17 | **day500** | *Day five hundred.* |
| 17–22 | **paywall** | *Three staves stay free. Always.* |
| 22–26 | End card | |

Never show a competitor's app or name one on screen; the hook describes the category, and the
stills answer it.
