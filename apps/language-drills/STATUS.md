stage: built
date: 2026-09-12
spec: SPEC.md · direction: DESIGN.md · qa: qa.json · privacy source: privacy.json
next: app-verify, then app-polish's critic → aso → shots → compliance → pages

## Where it stands

Scaffolded, implemented, looked at and verified on a `macos-26` runner with no human in the
loop. **Thousand** is the app; `language-drills` is the slug.

- **Builds against the iOS 26 SDK**, deployment target iOS 17, on an iPhone 17 Pro Max
  simulator running iOS 26.5. `xcodegen generate` runs before every build and no
  `.xcodeproj` is committed.
- **`.github/scripts/verify-app.sh language-drills` passes.** All seven screens in
  `qa.json` build, launch and render, the bundle check is clean, and no crash report
  belongs to `com.starhiveconcept.thousand`.
- **`node tools/design/tells.mjs language-drills` reports 0 hard tells and 0 smells.**
- **Every screen was read back as a PNG next to its mock**, in light, in dark and at the
  largest accessibility text size, before the commit that introduced it.
- **Listing written**, inside every limit: name 28/30, subtitle 25/30, keywords 91/100,
  promotional text 147/170, description 3195/4000. No word is repeated between the name,
  the subtitle and the keyword field, because App Store search indexes all three together.
- **Privacy generated, not hand-written.** `privacy.json` is the source; the manifest and
  the App Store privacy answers come from `tools/privacy/sync.mjs`.

## What works

- **The deck is a real thousand.** `content/band-01.json` … `band-10.json` hold 1,000
  common Spanish words in frequency order, evenly spread over the twelve themes (83 each,
  84 for body and health, 86 for nature and weather). Every entry has a word, a
  translation, an example sentence and its English translation.
  `content/build-deck.mjs` merges them into `ios/App/deck.json` and **refuses to write a
  deck that is wrong**: ranks must run 1…1000 with no gaps and no repeats, no headword may
  appear twice, every theme must be one of the twelve, nothing may be empty, and every
  example must actually contain the word it teaches. That last check is what caught the
  real mistakes; getting it to stop rejecting correct Spanish needed accent folding, stem
  changes at any vowel (poder → puedo, seguir → sigue, morir → murió), the -zco hardening
  (conocer → conozco), -z plurals (pez → peces), reflexive infinitives, and a short list of
  verbs that share no stem with their infinitive at all (ir → voy).
- **The turn**, which is the product. `TurningTile` is an `Animatable` view on the
  rotation angle, so its body is re-evaluated every frame: the specular band tracks the
  angle and sweeps the face, and a hairline of unglazed clay shows as the tile goes edge-on.
  `Haptics.soft` on the press, `Haptics.rigid` and `Tones.pop` at the edge-on frame,
  the landing on `Motion.bouncy`, then the three glaze chips rise staggered.
- **The three grades behave differently.** *Got it* flies the tile into its gap in the
  course through `matchedGeometryEffect` with `Tones.step(n)` climbing the scale; *Easy*
  does the same 80 ms faster with a lustre flash, a glaze-chip burst and `step(n + 2)`;
  *Not yet* drains the glaze to bisque behind a mask and slides the tile back into the
  stack with `Haptics.thud` and a low `Tones.miss`. Nothing turns red anywhere.
- **The teaching has no text.** On a player's first ever card the tile peeks to 14° and
  back twice, showing its clay edge, and stops for good the moment anything is touched.
  The only explanation in the app is the VoiceOver hint, which is allowed to explain.
- **The reward is full screen and tiered.** The tab bar and nav bar go away, the course
  expands into the whole wall, the session's tiles press in one at a time with the tone
  climbing, `CountUp` runs the hero at `brandDisplay(size: 100)`, and the tier decides how
  loud it gets: a lamp glow and `Tones.success` for a finished session, glaze-chip confetti
  and `.fanfare` for a clean one, and for a new hundred the loudest — a lustre sweep across
  the whole wall and the hero number held in amber.
- **The scheduler never invents work.** A session is what is due plus at most twelve words
  you have never met, and when there is nothing it says "The bench is swept." and stops.
  Grades feed an SM-2 style interval with a per-word ease; three clean firings in a row put
  a word in the wall for good. A word can still be summoned deliberately from the Wall
  with **Set it now**.
- **The Wall is the thousand as one object**: twelve panels of 44 pt tiles at a 3 pt grout
  gap, glazed / half-glazed / raw clay. `.searchable` drops the misses to 15 % opacity
  where they live rather than re-flowing the wall. Locked panels sit under a drawn dust
  sheet with a turned-back corner, and the free words inside them show through it.
- **Progress has one number and then draws the work**: due today and due tomorrow as two
  stacks of tiles on a kiln shelf in their own glazes, and mastery as twelve mortar bars,
  longest first. No streak, no calendar, and no sentence about their absence.
- **Pronunciation** is `AVSpeechSynthesizer` at `es-ES`, rate 0.46, fired by the chime
  glyph on the tile's back and automatically on the turn when *Say it on turn* is on.
- **The share card** is a picture of your own wall at 1080 × 1350 through
  `ShareImage.render` — the full thousand at 7 pt a tile, the hero count, and the newest
  word on one large cobalt tile.
- **The paywall** shows the one non-consumable with `-fakeProducts`, carries the promise
  line, and states no renewal terms because there is nothing that renews.
- `factoryReviewPrompt(afterSessions: 3)` is still wired.

## What is stubbed or standing in

- **`-sampleData` is a fiction, deliberately.** Nothing on a runner can drill for a
  fortnight, so it lays 213 words in the wall, 54 more drying, and a session waiting, in
  the shape a real fortnight would leave. It is only reachable from a launch argument.
- **The daily reminder is scheduled but never seen here.** `UNUserNotificationCenter`
  accepts the request on the simulator; whether it fires, and what it looks like on a lock
  screen, is a device question.

## What could not be checked without hardware

- **A real purchase.** No runner can complete one. The paywall was photographed with
  `-fakeProducts`, which injects a display offer; `Store.purchase` has never run against
  a real transaction here, and neither has **Restore purchases**.
- **Haptics.** Every beat is wired exactly as DESIGN.md's table says — `soft` on the press,
  `rigid` at the edge and on a tile setting, `thud` on *Not yet*, `impact(0.3)` per tile
  into the wall, `celebrate` on a clean session — and not one of them has been felt.
- **Sound.** `Tones` is silent under `-stillFrames` and a CI simulator has no output
  device, so the ceramic tick, the climbing scale and the fanfare have never been heard.
  The same goes for the Castilian speech: it was wired, never listened to.
- **The share sheet** needs hardware; only the rendered card was checked, by reading it.
- **Notifications firing.**

These five are the owner's TestFlight pass on a phone.

## Deliberate deviations from SPEC.md

- **The bundle id and product id.** SPEC.md names `com.factory.language-drills.pro`, which
  is both the old prefix and a subscription-shaped id for a one-time unlock. The app ships
  as `com.starhiveconcept.thousand` with `com.starhiveconcept.thousand.unlock`, matching
  the two most recent apps through the factory and the monetisation the spec actually
  describes.
- **The free tier is "the first 100 words and 2 themes" read as a union**, not an
  intersection: the Everyday and People & family panels in full, plus every word ranked
  100 or better wherever it lives. The scattered free words inside sheeted panels are what
  shows through the dust sheet, which turned out to be the clearest way to draw the offer.

## For the owner, before release

SPEC.md's second open item: **spot-check a sample of the deck and reject anything doubtful.**
Read `apps/language-drills/content/band-*.json` — ten files of a hundred, in frequency
order. The mechanical checks in `build-deck.mjs` prove the deck is well formed and that
each example contains its word; they cannot prove a translation is right.
