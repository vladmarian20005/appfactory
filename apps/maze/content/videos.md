# Lacework, five short videos

Format: vertical 1080×1920, 30 fps, 20–30 seconds, captions burned in, no voice. The app's own
tones are the soundtrack: the rising `.step` phrase along a bar, the `.pop` of a plait, the
`.fanfare` of a clean lift. Keep them in; they are the signature and nobody else in the
category sounds like this. Hooks are the leaders' own reviews (SPEC.md, *Wedge*).

Captions: New York Medium, walnut `#2A2521` on a parchment `#F8F3E7` strip with 10 px corners,
or white on the indigo `#31497A` for the end card. Never neon, never a sticker.

End card for every video (last 3–4 s): the icon, **Lacework**, "One-line maze. No ads, ever.",
and "On the App Store" once there is an id, "Coming soon" until then.

## Recording

**Not recorded yet** (28 Sep, content run). The app was not installed on the runner's
simulator and this run had no permission to build it (xcodegen, xcodebuild and
`tools/sim.sh` all asked for approval), and the runner has no ffmpeg. The clips below are
recorded by the next run that can build. Nothing on a runner can touch the screen, so every
shot uses a launch flag that makes the app perform it (`LaunchOptions.swift`).

```sh
# once
tools/sim.sh build apps/maze/ios Lacework
# per clip: start the recording, launch with the shot's flags, stop after the beat list
xcrun simctl io "$SIM_UDID" recordVideo --codec=h264 --force apps/maze/content/raw/0N.mov &
REC=$!
tools/sim.sh run apps/maze/ios Lacework -onboarded <flags from the shot>
sleep 25; kill -INT $REC; wait $REC
# vertical 1080×1920, 30 fps, the 6.9" capture padded rather than stretched
ffmpeg -i apps/maze/content/raw/0N.mov -vf "scale=1080:-2,pad=1080:1920:(ow-iw)/2:(oh-ih)/2:color=0xE8E0CF,fps=30" \
  -c:v libx264 -pix_fmt yuv420p -movflags +faststart apps/maze/content/clips/0N.mp4
```

The pad colour is the linen, so the letterbox reads as the canvas and not as black bars.
`content/raw/` stays out of git (large); `content/clips/*.mp4` is committed, as color-sort's is.

| Shot | Flags |
| --- | --- |
| **wind** — the thread winding itself, pin by pin, plaits forming | `-sampleData -board today -fresh -demo wind` |
| **lift** — the last pin, the pins coming out, the lace lifting, the margin card | `-sampleData -board today -demo lift` |
| **won** — the lift, already landed (for a still) | `-sampleData -screen win` |
| **sampler** — nineteen pieces, the month card | `-sampleData -screen sampler` |
| **book** — pattern 51, the chapters | `-sampleData -screen book` |
| **deep** — a fourteen-a-side card with windows, no end pinned | `-rung 500 -board book -fresh` |
| **first** — the first card, the ghost hand teaching | `-reset -demo first` (or `-lesson 1`) |
| **paywall** — one payment, today's stays free | `-sampleData -screen paywall -fakeProducts` |
| **workbox** — pieces, longest thread, days running | `-sampleData -screen workbox` |

---

## 1. "They promised no ads. Then level ten."

From Color Maze: *"After about the tenth level ad's start showing up."*

| s | Shot | On-screen text |
| --- | --- | --- |
| 0–3 | **wind**, first pins going in | *They promised no ads. Then level ten.* |
| 3–9 | **wind** continues, a plait tightens | *This one has no ad SDK in it at all.* |
| 9–15 | **book**, slow scroll down the chapters past fifty | *Not at level ten. Not at level five hundred.* |
| 15–22 | **lift** | *No lives. No timer. Nothing to watch.* |
| 22–26 | End card | *Lacework. One-line maze. No ads, ever.* |

## 2. "Got to level 70. Reset to 1."

From Color Fill 3D: *"Twice now I've got to level 70 ish and then open the app again and I'm
at level 1."*

| s | Shot | On-screen text |
| --- | --- | --- |
| 0–3 | **sampler**, the 19 at 112 pt | *Got to level 70. Reset to 1.* |
| 3–10 | **sampler**, scroll the cloth of small laces to the month card | *Every piece you finish is kept. Here.* |
| 10–16 | **workbox** | *On your phone. No account. No network.* |
| 16–22 | **wind** on today's pattern, then cut to the app relaunched: same thread, same pin | *Stop halfway. It is exactly where you left it.* |
| 22–26 | End card | |

## 3. "Watch 10 ads to keep playing? No."

From Maze Madness: *"now watch 10 ads and two more levels to overcome."*

| s | Shot | On-screen text |
| --- | --- | --- |
| 0–3 | **wind**, the brass start pin breathing | *Watch 10 ads to keep playing? No.* |
| 3–12 | **wind**, a long bar — the rising phrase is audible | *No hearts. No energy. No hint to buy.* |
| 12–18 | **wind**, the thread dead-ends and tugs, then picks out | *Go wrong? Pick the thread out. Free, always.* |
| 18–24 | **lift** | *The only thing at stake: was it worked clean.* |
| 24–28 | End card | |

## 4. "Every maze here has exactly one answer."

The praise side of the wedge: *"I don't like all these easy levels when you promise harder
puzzles"* (Color Maze Master).

| s | Shot | On-screen text |
| --- | --- | --- |
| 0–3 | **deep**, the 14×14 card with windows, nothing wound | *Every maze here has exactly one answer.* |
| 3–10 | **deep**, hold on it | *A solver proves it before the card is pricked.* |
| 10–15 | **book**, pattern 51 | *Five pins a side, climbing to fourteen.* |
| 15–22 | **wind** then **lift** | *Reach it by looking. Never by guessing.* |
| 22–26 | End card | |

## 5. "Maze games are all neon. This isn't."

The look is the argument: four of the five leaders are glowing arrows on black.

| s | Shot | On-screen text |
| --- | --- | --- |
| 0–3 | **won**, the lifted lace with its picot edge, held still | *Maze games are all neon. This isn't.* |
| 3–12 | **wind** from a fresh card, sound up | *One thread, every pin, on a lacemaker's pillow.* |
| 12–19 | **lift** | *Then the pins come out and it lifts off.* |
| 19–24 | **sampler** | *Into the sampler. A pattern a day.* |
| 24–28 | End card | |

Alternate opener for 5, for anyone who has never played one: **first**, the ghost hand
leading the thread along the lane, text *No idea how these work? Thirty seconds.*
