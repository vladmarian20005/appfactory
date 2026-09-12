# Thousand · design

## The idea

**A Sevillian tile-setter's workshop: a thousand Spanish words fired as glazed azulejo tiles,
each one turned over on the bench, read, and pressed into a wall that only ever grows.**

Three words: **fired, patient, kept.**

What it is NOT: the category. All five leaders are the same app — a flat saturated brand
primary edge to edge (Duolingo green, Memrise yellow, Quizlet purple), a heavy rounded sans
shouting a marketing headline, circular national flags in a row, a cartoon mascot with
eyebrows, and a HUD of hearts, gems and a streak flame over a progress bar. The flashcard
apps underneath them (Anki, Quizlet's study mode) are the opposite failure: a white or black
utility screen, a text field and a table. Thousand is neither. It is clay, glaze and lime
plaster, and every screen is a wall being built.

Why tile, and not a skin over tile: the spec's whole wedge is **permanence** — bought once,
no server, no subscription, no streak to break, a thousand words that stay learned. A glazed
tile is the most permanent object a person owns; a wall of them is the only progress bar that
is also a finished thing. The scheduler fits it exactly: a word you nearly forgot is a tile
that has not set yet and goes back to the bench, unglazed, for another firing. Nothing is
lost, nothing is punished, and the work is visible from across the room. The idea chooses the
cobalt, the lime plaster, the wide painted lettering, the grout grid, the ceramic tick, and
the voice of the man who lays them.

And it is Spanish without a single flag: azulejo is what the language looks like in Seville,
Talavera and Puebla.

## Who and when

He is 29, learned enough Spanish on a free app to lose it again, and is going back at it in
the ten minutes before bed and the twenty on the train, where the signal drops in the tunnel.
He is not chasing a streak and has already resented paying a subscription for one; he wants
the words to still be there in March. The feeling he comes for is **quiet accumulation** —
proof that something is being built and kept, without a cartoon telling him he has been away
for three days.

## The signature interaction

**The turn.** One tile at a time on the bench: he reads the Spanish, turns the tile over,
sees whether he was right, and says how it went. He does it forty times a session and
thousands of times over the app's life, so it is the product.

The card is not a white rounded rectangle. It is a **glazed tile**, 318 × 318 pt at corner
radius 12, and it is painted on both faces the two ways a tile shelf paints them:

- **The prompt face** (the Spanish) is *glaze ground, cream letters*: the theme's glaze as a
  vertical gradient, the glaze colour at the top to 14 % deeper at the bottom, with the word
  painted across it in cal at 56 pt.
- **The answer face** (the English) is the other way round — *cream ground, glaze painting*: a
  15 pt band of the theme's glaze all round, four amber corner motifs on the band, and inside
  it a cream field (`#F7F0E3` → `#F0E6D4`, and `#DCD2C0` in dark mode so it does not glare)
  carrying a 1.5 pt glaze fillet, the English at 46 pt **in the glaze colour**, a hairline, the
  example in body italic and its translation in Sombra.

Both faces have the pressed bevel — a 3 pt inner light on the top and left edges, a 3 pt inner
shadow on the bottom and right — and a specular band at about 102° across the face. Text on the
answer face is always Carbón and Sombra whatever the mode, because the face is light in both
(`#2B211A` on `#DCD2C0` is 10.50, `#63564A` on it 4.74). The word's rank sits top right in a
small tracked mark; the Spanish stays top left in the glaze colour, so the answer is never
divorced from the word that asked for it. Around it, the bench: two bisque tiles waiting
behind, offset 8 pt and 16 pt down. `mock-1-play` shows the face a beat after the turn.

| ms | what happens |
| --- | --- |
| finger down | The tile presses: `.buttonStyle(.pressable)` at scale 0.985, the specular band slides 6 pt down its face, `Haptics.soft()`. |
| 0–170 | **The turn begins.** `rotation3DEffect` about the vertical axis, perspective 0.62, 0° → 90°, `Motion.snappy` (response 0.34, damping 0.86). The specular band tracks the angle and sweeps the full face as it goes edge-on — the glaze catching the light is the whole point of the motion. |
| 170 | **The edge.** At 90° the faces swap. `Haptics.rigid()` and `Tones.shared.play(.pop)` — the ceramic tick of a tile set down on stone. The tile is 3 pt thick here: a hairline of unglazed clay `#C7B49B` shows on the edge. |
| 170–340 | **The landing.** 90° → 180° on `Motion.bouncy`, overshooting 4° and settling. The answer face arrives as described above, with the **chime** — a drawn glyph of three arcs in a glaze-tinted well — in the lower-left corner. |
| 340–460 | **The grades rise.** Three glaze chips come up from the bottom edge, `.popIn(delay:)` staggered 0.05 s: **Not yet** and **Easy** as *outlined* chips in almagre and verdigris on the plaster, **Got it** filled in cobalt and 30 % wider — the common answer is the one with weight, so three coloured pills never read as a row of sweets. Capsules, not squares: they are the only round things on the screen, so the eye finds them. |
| on **Not yet** | The tile's glaze drains to bisque over 0.22 s (a mask wiping top to bottom) and it slides back into the stack behind the bench on `Motion.gentle`, with `Haptics.thud()` and `Tones.shared.play(.miss)` — a low, soft note, never a buzzer. Nothing turns red; the tile is simply not fired yet. |
| on **Got it** | The tile shrinks to 26 pt on a 0.32 s arc up into the **course** — the single row of the session's tiles along the top of the screen — and presses into its gap with `Haptics.rigid()` and `Tones.shared.play(.step(n))`, where n is how many have set this session, so a good run climbs the scale. |
| on **Easy** | The same flight at 0.24 s, and on landing the tile flashes a lustre (a white sweep at 40 % across it in 0.18 s), an 8-particle glaze-chip burst in its own colour, `Haptics.impact(0.6)`, `Tones.shared.play(.step(n + 2))`. Easy is audibly two notes brighter. |
| after | The next tile rises from the stack, +40 pt and scale 0.94 → 1.0 on `Motion.gentle`, and the due count on the course drops by one. |

**Why it holds up the thousandth time:** the specular sweep is tied to the rotation, so the
turn reads as a physical object catching a window rather than a card animation; the tick lands
at the edge-on frame, which is exactly where the eye expects the sound; and because the tone
tracks the number set this session, the fortieth tile of a good round sounds different from
the fortieth of a rough one. The course at the top visibly shortens — the session is a bar
that empties, and the wall is a bar that fills, and they are the same tiles.

**Teaching the first one, with no text.** On a player's very first card the tile **peeks**:
it rotates to 14° and back over 0.9 s on `Motion.gentle`, twice, with two seconds between,
showing a sliver of its clay edge and the bisque behind. It stops the instant the first tile
is touched and never returns. Nowhere does the app say "tap the card to flip it". The
VoiceOver hint is the exception and does explain: *"Turns the tile over to show the English."*

## The reward

**The bench is swept and the day's tiles are in the wall.** Full screen on the brand canvas,
never a sheet, never a checkmark seal, about 1500 ms.

| ms | what happens |
| --- | --- |
| 0 | The last tile flies up to the course. The bench empties: the stack slides out of frame down, the grades fall away. |
| 0–260 | **The pull-back.** The course expands into the wall — the session's tiles keep their positions and the rest of the wall grows around them from scale 1.06 to 1.0 on `Motion.gentle`, so the eye sees the day's work land inside the whole. |
| 120–520 | **The setting.** Each tile of the session presses into the wall in order, `.popIn(delay:)` staggered 0.05 s, each with `Haptics.impact(0.3)` and `Tones.shared.play(.step(n))` climbing. Mortar (a 2 pt line of canvas colour) draws around each as it lands. |
| 300–800 | **The count.** The hero number counts with `CountUp(to: known, onTick:)` at `.brandDisplay(size: 100)` in ink — `213` — over a small tracked `OF A THOUSAND` in `inkSoft` and, under that, `+24 SET TODAY` in amber. Every tick is `Haptics.impact(0.35)`. The tiles set today keep a 1.5 pt amber mortar ring in the wall for the rest of the day, so the eye can find the day's work inside the thousand. |
| 700–1000 | The **wall line** draws itself: a 3 pt rule 292 pt wide with a filled portion in cobalt at `known / 1000` and a small amber notch at the next hundred, marked `THE WALL` and `300 NEXT`. |
| 800 | The praise line sets under it at `.brandFont(.title2)` in the display face, from the setter's pool, with one quiet line of fact under it in `inkSoft` — *"Twelve panels standing, three still bare plaster."* |
| 900 | **Tiers.** *Set* (the session finished, some tiles came back): the lamp glow swells behind the wall over 0.5 s, `Haptics.success()`, `Tones.shared.play(.success)`, **no confetti** — a normal day is not a parade. *Clean* (nothing went back to the bench): `confetti(trigger:power: 1.1)` in glaze chips, `Haptics.celebrate()`, `Tones.shared.play(.fanfare)`. *A new hundred* (the session crossed 100, 200 … 1000 known): the loudest — `confetti(power: 1.5)`, `Haptics.celebrate()`, `.fanfare`, and a **lustre sweep** travels the whole wall left to right over 0.7 s, lighting each course of tiles as it passes, with the hero number held in amber. |
| after | **Back to the wall** (prominent), **Share the wall**. `mock-2-win` shows the peak. |

**Small rewards inside the loop.** Every tenth tile set in a session, the course's tenth gap
takes a thin amber mortar line and `Tones.shared.play(.step(10))` rings a note above the
others — a small brightening, not an interruption. A word reaching *known* (its third clean
firing) glazes fully as it flies: the bisque back turns to the theme's glaze in flight, with
`Haptics.impact(0.5)`.

Under `-stillFrames` the setting resolves in one frame and the confetti freezes at its peak,
so a capture shows a finished wall. Demo moments for the critic's filmstrips: `-demo turn`
plays one full turn and a **Got it**; `-demo win` plays the clean-session reward.

## Look

### Palette

Every role has a light and a dark value. Light is **the workshop at eleven in the morning**,
lime plaster and daylight. Dark is **the same workshop at night with the lamp on** — deep
indigo, the plaster gone blue, the glazes lit rather than inverted.

| Name | Role | Job | Light | Dark |
| --- | --- | --- | --- | --- |
| **Cal** | `canvas` | lime-plaster wall behind everything | `#EDE3D6` | `#131826` |
| **Bisque** | `surface` | unfired clay: panels, the bench, unglazed tiles | `#E0D2C0` | `#1F2536` |
| **Carbón** | `ink` | primary type and painted glyphs | `#2B211A` | `#F1E7D8` |
| **Sombra** | `inkSoft` | secondary type, translations, captions | `#63564A` | `#9AA3B5` |
| **Cobalto** | `accent` | the signature glaze: primary actions, *Got it*, known tiles, the wall line | `#1C5AA6` | `#5C9BE8` |
| **Cal glaseada** | `onAccent` | painted lettering on a glaze | `#F4ECDD` | `#0B1524` |
| **Azafrán** | `highlight` | the second voice: the lamp, the lustre, a new hundred, the next-hundred notch | `#A8701B` | `#F0B450` |
| **Verde de cobre** | `success` | *Easy*, a word fully fired | `#2F6B57` | `#4FA084` |
| **Almagre** | `miss` | *Not yet* — red ochre, a glaze colour, warm and forgiving | `#9E4630` | `#D2714F` |

Green and red never mean right and wrong here: verdigris and almagre are both glazes on the
shelf, and *Not yet* is a tile going back for another firing, not an error.

**Checked** — `node tools/design/contrast.mjs`:

```
light   #2B211A on #EDE3D6  12.40  AAA   ink on canvas
        #2B211A on #E0D2C0  10.60  AAA   ink on surface
        #63564A on #EDE3D6   5.59  AA    inkSoft on canvas
        #63564A on #E0D2C0   4.78  AA    inkSoft on surface
        #F4ECDD on #1C5AA6   5.84  AA    onAccent on accent
        #F4ECDD on #2F6B57   5.32  AA    onAccent on success chip
        #F4ECDD on #9E4630   5.30  AA    onAccent on miss chip
        #1C5AA6 on #EDE3D6   5.41  AA    accent as text on canvas
        #A8701B on #EDE3D6   3.31  large only — amber is a glow and a large number, never body
tile    #2B211A on #F4ECDD  13.40  AAA   ink on the answer face, light
        #1C5AA6 on #F4ECDD   5.84  AA    the glaze as painted letters on it
        #63564A on #F4ECDD   6.04  AA    the translation on it
        #2B211A on #DCD2C0  10.50  AAA   ink on the answer face, dark mode
        #63564A on #DCD2C0   4.74  AA    the translation on it, dark mode
dark    #F1E7D8 on #131826  14.47  AAA   ink on canvas
        #F1E7D8 on #1F2536  12.47  AAA   ink on surface
        #9AA3B5 on #131826   6.98  AA    inkSoft on canvas
        #9AA3B5 on #1F2536   6.02  AA    inkSoft on surface
        #0B1524 on #5C9BE8   6.37  AA    onAccent on accent
        #F0B450 on #131826   9.57  AAA   highlight on canvas
        #D2714F on #131826   5.24  AA    miss on canvas
        #4FA084 on #131826   5.64  AA    success on canvas
```

One rule falls out of it: **amber on bisque is never text** (2.83 in light). On a surface,
labels are ink or cobalt; amber there is a fill or a glow only.

### The twelve glazes

One per theme, so a tile's colour tells you what it is before you read it, and the wall reads
as twelve panels. They are the azulejo shelf, not a category rainbow.

| Theme | Glaze | Light | Dark |
| --- | --- | --- | --- |
| Everyday | cobalto | `#1C5AA6` | `#5C9BE8` |
| People & family | almagre | `#9E4630` | `#D2714F` |
| Food & drink | verde de cobre | `#2F6B57` | `#4FA084` |
| The house | ocre | `#A8701B` | `#C9963F` |
| City & travel | turquesa | `#2A7E8E` | `#46AFC0` |
| Work & school | índigo | `#35468C` | `#6376C8` |
| Body & health | rosa de barro | `#A55A6A` | `#D18B99` |
| Time & number | manganeso | `#6B4E7D` | `#9A79AE` |
| Nature & weather | oliva | `#5E6B2C` | `#93A24C` |
| Going & coming | berenjena | `#5B3550` | `#8C5C80` |
| Feeling & mind | azafrán | `#8F5E12` | `#F0B450` |
| Describing | pizarra | `#41505C` | `#7C8896` |

### Canvas

A **nine-point mesh** of lime-plaster tones through `brandBackground(drift: true)` — plaster
is never one flat colour, it is troweled, and the mesh gives it that mottle. In light, warm
daylight from the top-left and a cooler shadow bottom-right. In dark, night indigo with one
warm point at the top-right: the workshop lamp. It drifts very slowly and stands still under
`-stillFrames` and Reduce Motion. Over it, on the Bench screen only, a `Canvas` grain pass:
900 short strokes at 3 % ink, seeded once, that reads as trowel texture and never moves.

### Type

Display is **SF Expanded, semibold** (`BrandType(display: .default, displayWidth: .expanded,
displayWeight: .semibold)`). Hand-painted tile lettering is wide, generous and flat-footed,
and it is the one width no other app in this category uses — Duolingo, Babbel and Memrise are
all heavy rounded or condensed grotesques. Body is SF at default width, and example sentences
are body italic, because that is how a translation is set.

Hero numbers through `brandDisplay(size:)`: **104 pt** for words known on Progress and
**100 pt** on the win, **72 pt** for the due count when a session is waiting, **56 pt** for the
Spanish word on the prompt face and **46 pt** for the English on the answer face (both step
down to 40 and then 30 for long words and large Dynamic Type settings).
Small tracked uppercase in SF at 11 pt, tracking 1.6 — `OF A THOUSAND`, `DUE TODAY`,
`THE HOUSE · 34 OF 80` — are the marks written on the bench, and they are the only uppercase
in the app.

### Shape

**The tile**: a square. Radius 12 on the big drill tile and on panels (`corner: 12`), 6 on the
theme grid's 44 pt tiles, 2 on the wall's 9 pt tiles. Every tile carries the same bevel — inner
light top-left, inner shadow bottom-right — scaled to its size, and every grid of them has a
**3 pt grout gap** in canvas colour. The only capsules in the app are the three grade chips and
the system's own prominent buttons; that contrast is deliberate, so the thing you tap next is
never in doubt.

### Art

Four SVGs in `design/art/`, rendered into the asset catalog with `tools/design/art.mjs`:

| File | Where | What it depicts |
| --- | --- | --- |
| `wall-at-noon.svg` | onboarding 1 (`mock-3-first`) | A lime wall with a mosaic panel half laid, one starred cobalt tile hovering over its gap, the mortar combed in the gap beneath it |
| `the-bench.svg` | onboarding 2 | The workbench: three tiles drying in a row, a brush laid across an open jar of cobalt glaze, a rag |
| `kept-wall.svg` | onboarding 3 and the paywall hero | The finished wall under a hanging lamp, courses receding, twelve panels of glaze reading as one thing |
| `swept-bench.svg` | the empty state when nothing is due | The same bench, empty and swept, tools laid down, late light across it |

Built in SwiftUI rather than drawn, because they move part by part: the drill tile (glaze
gradient, bevel, specular band, the clay edge), the wall mosaic, the course at the top of the
bench, the kiln stacks on Progress, and the glaze-chip confetti. No SF Symbol is ever the hero
of a screen; symbols appear only inside system chrome (the tab bar, the toolbar) and as the
chime and search glyphs at text size.

### Motion

| What | Spring |
| --- | --- |
| The turn, chip presses, the tile rising from the stack | `Motion.snappy` |
| The landing overshoot, tiles pressing into the wall, the count-up's scale | `Motion.bouncy` |
| Panels, the example sentence rising, a tile draining to bisque, screen changes | `Motion.gentle` |
| The lustre flash on *Easy* | `Motion.pop` |

Ambient, all of it `Motion.isStill`-aware: the plaster mesh drifts; the lamp glow
`.breathing()` on a 5.2 s period in dark mode; on the Wall, a slow specular sheen crosses one
random glazed tile every ~6 s, 0.9 s long, so the wall is alive but never busy.

**What never moves:** the grout grid, the courses' positions, the type. A tile that is set is
set. Nothing in this app idles with a bounce.

### Sound

`Tones` on the ambient session, `SoundsToggle()` in Settings:

| Where | Tone |
| --- | --- |
| Picking up a tile | `.tap` |
| The edge of the turn | `.pop` — the ceramic tick |
| A tile setting into the course | `.step(n)`, n = tiles set this session |
| *Easy* | `.step(n + 2)` |
| *Not yet* | `.miss`, low and short |
| Session done | `.success` |
| A clean session or a new hundred | `.fanfare` |

**Pronunciation** is `AVSpeechSynthesizer` at `es-ES`, rate 0.46, on the same ambient session,
fired by the chime glyph on the tile's back and automatically once when a card turns if
*Say it on turn* is on in Settings (default on). It shares the session deliberately: the
user's music keeps playing and the silent switch silences the app, which is what a phone in a
pocket on a train should do. If TestFlight says people think pronunciation is broken with the
ringer off, the speech session — and only the speech session — moves to `.playback` with
`.mixWithOthers`.

## Voice

**The setter.** An alicatador who has laid tile for thirty years, works standing up, and talks
about clay, glaze, the kiln and the wall — never about apps, levels or days. He is pleased for
you without making a performance of it, and he never counts what you missed.

Three rules: **(1)** nine words or fewer; **(2)** concrete nouns from the workshop, never
abstractions like "progress" or "journey"; **(3)** a forgotten word is a tile that needs
another firing, never a mistake — nothing he says can be read as a scold.

### Onboarding — three pages

| | Title | Subtitle |
| --- | --- | --- |
| 1 · `wall-at-noon` | **A thousand words, one wall.** | The words you actually meet, in the order you meet them. |
| 2 · `the-bench` | **Turn it over. Say how it went.** | Each tile comes back exactly when it is about to slip. |
| 3 · `kept-wall` | **Bought once, kept for good.** | The whole wall lives on this phone. No subscription, nothing to renew. |

Page 3 is the one place in the product that states the deal, as TASTE.md allows. Button:
**Set the first tile.**

### Praise pool — the session is done (10, never the same twice running)

- "The wall grew today."
- "Straight courses, no gaps."
- "That glaze took well."
- "Clean work. The kiln did its part."
- "You set those without looking twice."
- "Every one of them held."
- "The bench is clear."
- "Good hands today."
- "That course is true."
- "Mortar's dry. It stays."

### Near-miss pool — several tiles went back (8)

- "A few went back to the bench."
- "Clay before glaze. That is the order."
- "Some want a second firing."
- "The wall does not mind waiting."
- "Two courses forward, one relaid."
- "They will come good."
- "Nothing lost. Set aside."
- "That is how a wall gets straight."

### The win headline, by tier

| Tier | Headline |
| --- | --- |
| **Set** — session finished | **The bench is clear.** |
| **Clean** — nothing went back | **Not one back to the bench.** |
| **A new hundred** — crossed 100, 200 … | **Three hundred in the wall.** (the hundred, spelled) |

### Empty states

| Where | Line | Under it |
| --- | --- | --- |
| Nothing due today (`swept-bench`) | **The bench is swept.** | Twenty-two tiles are drying. Eleven are ready tomorrow. |
| Search finds nothing | **No tile by that name.** | — |
| A locked theme | **Under the dust sheet.** | Eighty tiles, glazed and waiting. |
| The wall before any word is known | **Bare plaster.** | The first course goes in today. |

### No streak — and what stands in its place

There is no streak, no calendar of missed days and no flame anywhere in this app; the spec is
right that the absence is the product. It is never *mentioned*, only absent. What the Progress
screen says instead of a streak is the only number that compounds: **words known, of a
thousand**, which cannot go down.

The daily reminder is off by default, set in Settings, and names work rather than guilt:

> **Thousand** — Eleven tiles are ready at the bench.

It never says "don't break your streak", "you haven't practised in 3 days" or anything that
counts absence.

### Paywall

**Headline:** The whole wall.

- All 1,000 words, every one of the twelve panels.
- Works in a tunnel, on a plane, with the phone in a bag.
- One payment. No subscription, ever.

**Promise:** *One payment opens the whole thousand, on this phone, offline, for good.*

Buttons: **Open the whole wall · $9.99** (prominent), **Restore a purchase**.

### Button labels — every primary action

| Where | Label |
| --- | --- |
| Onboarding, last page | Set the first tile |
| Bench, cards due | **Set 24 tiles** (the count is live) |
| Bench, the tile | the tile itself; VoiceOver: *Turn the tile over* |
| The three grades | Not yet · Got it · Easy |
| Hear the word | the chime glyph; VoiceOver: *Hear it in Spanish* |
| Session done | Back to the wall · Share the wall |
| Nothing due | See the wall |
| A word opened from the Wall | Set it now |
| A locked panel | Open the whole wall |
| Paywall | Open the whole wall · $9.99 · Restore a purchase |

Never "Continue", never "OK", never "Got it!" as a dismiss (it means a grade here).

## Screens

Three tabs in a system `TabView` — **Bench**, **Wall**, **Progress** — plus Settings in the
Bench's toolbar. The tab bar, navigation bars, sheets, `Toggle`, `Picker`, the search field
and every `Button` are the system's, tinted cobalt, so they take Liquid Glass from the iOS 26
SDK. Everything below the chrome — tiles, the wall, the course, the kiln stacks — is drawn.

### Bench — the drill · `mock-1-play`

**Its one job:** turn the tile in front of you and say how it went. Nothing else is on screen.

Top to bottom: the **course** — the session's row of 12 pt tile slots across the full width
under the nav bar, filled ones in their glaze, the rest as empty grout gaps recessed with an
inner shadow, the current theme tracked small at its left end and `15 DUE` at its right,
shrinking as tiles set. Then the **tile**, 318 × 318, centred with the two bisque tiles of the
stack behind it; the tile and its three chips are centred **together as one block**, 38 pt
apart, so neither floats. Before the turn the tile shows the glaze face and there is nothing
under it at all — the affordance is the tile. After the turn it shows the cream-field face and
the chips rise.

**What moves:** the turn and its specular sweep; the grade chips rising; the tile flying to
the course or draining to bisque; the next tile rising from the stack; the plaster drifting.

**When nothing is due:** the `swept-bench` art, "The bench is swept.", the two drying/ready
counts as small tile stacks, and **See the wall**. The app never invents cards to fill a
session — there is no "study anyway" button here; a single word can still be summoned
deliberately from the Wall.

### Wall — the deck · the mosaic

**Its one job:** show that the thousand is a real, finite, visible object, and let any word in
it be found.

A scrolling mosaic of **twelve panels**, one per theme. Each panel: the theme name in tracked
uppercase with `34 OF 80` at its right and a 2 pt mortar line filled in the theme's glaze,
then a grid of 44 pt tiles at a 3 pt grout gap — **raw clay** (matte bisque, no bevel light)
for new, **half-glazed** (the glaze at 45 % with the bevel, a diagonal clay edge showing) for
learning, **glazed** (full colour, full bevel, specular) for known. Tap any tile for its word
in a sheet: the tile large, the example, the chime, **Set it now**.

The system's `.searchable` filters: non-matching tiles drop to 15 % opacity over 0.2 s rather
than disappearing, so the wall never re-flows and you can see where a word lives. Locked
panels are drawn **under a dust sheet** — the tiles at 30 % under a translucent canvas-coloured
scrim with a soft hanging fold — and tapping one lifts a corner of the sheet before the paywall
rises.

**What moves:** the sheen crossing a random glazed tile; a tile glazing when the sheet is
dismissed after a word came good; the dust sheet's corner lifting.

### Progress · the count

**Its one job:** one number that only goes up, and where the work is.

The hero, top: `213` at 104 pt in ink over `OF A THOUSAND`, with the wall line beneath it —
a hairline with the known portion in cobalt and an amber notch at the next hundred. Then
**the kiln shelf**: due today and due tomorrow drawn as two actual stacks of tiles at true
scale (24 tiles and 11, in their own glazes), captioned `DUE TODAY` and `TOMORROW` — never a
row of identical number tiles with grey captions. Then **the twelve panels** as twelve mortar
bars in their glazes, longest first, each with its theme name and `34 / 80`.

No calendar. No streak. No days-in-a-row anything, and no sentence about their absence.

**What moves:** the hero number counts up when the screen appears (`CountUp`, 0.6 s); the
mortar bars draw left to right, staggered 0.04 s.

### Settings

The system's `Form` on `.brandBackground()`: *Say it on turn*, `SoundsToggle()`, the daily
reminder and its time, then the kit's restore, rate, share, support and privacy rows. System
chrome, brand tint, nothing drawn.

### Paywall — `PaywallView`

`kept-wall` as the hero, the headline, three bullets, the promise line, the price button,
restore. The one screen allowed to say what the deal is.

### Onboarding — `mock-3-first`

Three `OnboardingPage`s with the art above, on `.brand(AppBrand.brand)` so the very first
frame is already plaster and cobalt.

## Icon

`design/icon.svg` → `design/icon-1024.png`.

**The concept:** a single azulejo tile, freshly glazed, set into lime plaster with its
neighbours cropping at the edges. **The composition:** full bleed, square corners; a cobalt
tile filling the middle ~76 % of the frame at radius 60 (1024 scale), bearing a hand-painted
eight-point star in cream with an amber centre — the oldest motif on a Spanish tile and
readable at 60 pt; a 3 % rotation off square, because a hand set it; a soft specular band
across the top-left corner and the pressed bevel on all four edges; around it, plaster and the
grout lines of four neighbouring tiles, one of them bisque, so the wall is implied.

**The colours:** plaster `#EDE3D6`, tile cobalt `#1C5AA6` → `#174B8B` vertical, motif cream
`#F4ECDD`, motif centre `#E0A03C`, grout shadow `#C9B79F`, bisque neighbour `#E0D2C0`.

Never a letter, never a number, never "1000" on a gradient.

## Share card

`ShareImage.render` at **1080 × 1350**, on the plaster canvas:

- The **wall** across the middle: the full thousand at 9 pt a tile in twelve panels, known
  tiles in their glaze, learning half-glazed, the rest bare clay — so the picture *is* the
  progress, and two people's cards look different at a glance.
- The hero: `213` at 180 pt over `OF A THOUSAND`, with the session's count in amber beneath —
  `+24 TODAY`.
- The newest word set, painted on one large cobalt tile in the lower left: `la ventana`.
- The date in tracked small caps at the bottom, and `THOUSAND` at the bottom right.

A line of text is the fallback: *"213 of a thousand Spanish words. la ventana went in today."*

This is the one place a frozen point size is allowed — `ShareImage.render` draws into an
`ImageRenderer` at a fixed pixel size, so `180` here is 180 pixels, not a Dynamic Type size.

## Tokens

```swift
import FactoryKit
import SwiftUI

/// Thousand's look, from DESIGN.md. A tile-setter's workshop: lime plaster, clay and glaze.
enum AppBrand {
    static let brand = Brand(
        palette: BrandPalette(
            canvas:    Color(light: 0xEDE3D6, dark: 0x131826),   // cal — lime plaster
            surface:   Color(light: 0xE0D2C0, dark: 0x1F2536),   // bisque — unfired clay
            ink:       Color(light: 0x2B211A, dark: 0xF1E7D8),   // carbón
            inkSoft:   Color(light: 0x63564A, dark: 0x9AA3B5),   // sombra
            accent:    Color(light: 0x1C5AA6, dark: 0x5C9BE8),   // cobalto
            onAccent:  Color(light: 0xF4ECDD, dark: 0x0B1524),   // cal glaseada
            highlight: Color(light: 0xA8701B, dark: 0xF0B450),   // azafrán — the lamp
            success:   Color(light: 0x2F6B57, dark: 0x4FA084),   // verde de cobre
            miss:      Color(light: 0x9E4630, dark: 0xD2714F),   // almagre
            extras: [
                Color(light: 0x1C5AA6, dark: 0x5C9BE8),   // 0  cobalto        · Everyday
                Color(light: 0x9E4630, dark: 0xD2714F),   // 1  almagre        · People & family
                Color(light: 0x2F6B57, dark: 0x4FA084),   // 2  verde de cobre · Food & drink
                Color(light: 0xA8701B, dark: 0xC9963F),   // 3  ocre           · The house
                Color(light: 0x2A7E8E, dark: 0x46AFC0),   // 4  turquesa       · City & travel
                Color(light: 0x35468C, dark: 0x6376C8),   // 5  índigo         · Work & school
                Color(light: 0xA55A6A, dark: 0xD18B99),   // 6  rosa de barro  · Body & health
                Color(light: 0x6B4E7D, dark: 0x9A79AE),   // 7  manganeso      · Time & number
                Color(light: 0x5E6B2C, dark: 0x93A24C),   // 8  oliva          · Nature & weather
                Color(light: 0x5B3550, dark: 0x8C5C80),   // 9  berenjena      · Going & coming
                Color(light: 0x8F5E12, dark: 0xF0B450),   // 10 azafrán        · Feeling & mind
                Color(light: 0x41505C, dark: 0x7C8896),   // 11 pizarra        · Describing
            ]
        ),
        // Hand-painted tile lettering is wide. Nobody in this category is.
        type: BrandType(display: .default,
                        displayWidth: .expanded,
                        displayWeight: .semibold,
                        body: .default),
        corner: 12,
        // Troweled plaster: daylight from the top-left in light, the workshop lamp
        // top-right at night. Never one flat colour.
        canvas: .mesh([
            Color(light: 0xF5ECE0, dark: 0x161C2C), Color(light: 0xF0E6D9, dark: 0x1A2134), Color(light: 0xF3E8D6, dark: 0x232741),
            Color(light: 0xEDE3D6, dark: 0x121726), Color(light: 0xEADFD0, dark: 0x161B2B), Color(light: 0xE8DCCB, dark: 0x1B2135),
            Color(light: 0xE6D9C7, dark: 0x0F1420), Color(light: 0xE3D6C3, dark: 0x121724), Color(light: 0xE0D2C0, dark: 0x0E1320),
        ])
    )

    /// The clay edge a tile shows when it turns — the one colour that is neither
    /// plaster nor glaze.
    static let clayEdge = Color(light: 0xC7B49B, dark: 0x3A3730)

    /// The cream ground of a tile's answer face. Light in both modes — dimmed at night so it
    /// does not glare — so its text is always `faceInk` and `faceInkSoft`, never the palette's.
    static let tileFace = Color(light: 0xF4ECDD, dark: 0xDCD2C0)
    static let faceInk = Color(hex: 0x2B211A)
    static let faceInkSoft = Color(hex: 0x63564A)

    /// The amber the corner motifs and the fresh mortar ring are painted in.
    static let motif = Color(hex: 0xE0A03C)

    /// The glaze of a theme, by its index in the deck's twelve.
    static func glaze(_ theme: Int) -> Color {
        brand.palette.extras[theme % brand.palette.extras.count]
    }
}
```

Applied once at the root: `.brand(AppBrand.brand)` on `RootView` **and** on `OnboardingView`,
so the very first frame is already the workshop.

**Every size in this document is a Dynamic Type size.** Text comes from `brandFont(_:)`,
`brandDisplay(size:)` or `scaledFont(size:)` — never `.font(.system(size:))` and never a
`-> Font` helper that returns one, which `tells.mjs` fails: the small tracked marks are
`scaledFont(size: 11)`, the tile's word is `brandDisplay(size: 56)`. The one exception is the
share card, which `ShareImage.render` draws at a fixed pixel size with no Dynamic Type to
scale against.

## Slop we are avoiding

The three this genre falls into hardest, and what Thousand does instead:

1. **A white card on a grey background, with the word in the middle.** Every flashcard app on
   the store is this, and it is the first slop tell in TASTE.md. Thousand has no white and no
   card: the unit is a *glazed tile* with a bevel, a specular band and a clay edge, on troweled
   plaster. One crop of any screen identifies the app.

2. **A result that is "18 / 24" in a card, then "Come back tomorrow".** Instead the session
   ends as the day's tiles pressing into a wall you keep, a 104 pt number that only ever goes
   up, three tiers with different sound and light, and a share card that is a picture of your
   own wall rather than a score.

3. **Stats as a row of identical number tiles with grey captions, next to a streak flame.**
   Progress has one hero number and then draws the work itself: due today and tomorrow as
   actual stacks of tiles at true scale, mastery as twelve mortar bars in the themes' own
   glazes. No streak, no calendar, no flame — and no sentence pointing out that they are
   missing.

And, standing behind all three: nothing in the product recites the pitch. "No ads", "no
subscription", "nothing runs out" and "works offline" appear on the store listing and on the
paywall and onboarding page 3 — nowhere else. Inside the app the absence is felt as a screen
that never asks for anything.

## Roads not taken

- **The lotería print shop** — each word an illustrated card sung by a caller in a night
  market: the warmest idea of the three, and impossible here, because it needs a thousand
  hand-drawn illustrations and this factory draws SVG on a runner.
- **The night sky over the Meseta** — the thousand words as stars, known ones lit, a
  constellation per theme, drilling as pulling one into focus: beautiful, but it is Tidepour's
  dark glow-on-deep-blue again, and a sky cannot show "this word is not fired yet" the way
  clay can.
