stage: built
date: 2026-09-24
next: app-verify

Lacework is built from SPEC.md in DESIGN.md's direction, on ARCHITECTURE.md's structure
(the changes are noted at the bottom of that file).

## What works

- **The generator is the build.** `Generator.swift` threads a Hamiltonian path over the card's
  mask (Warnsdorff DFS, then backbite), lays gimp on every neighbouring pair the thread does not
  join, and lifts it in the ground's order wherever `Solver.swift` still proves exactly one way
  through (12,000-node budget per removal). Measured on the runner, compiled `-O`: 5×5 in under
  a millisecond, 9×9 in ~20 ms, Sunday's daily (14×14, one window, finish loose) in 0.8–1.2 s,
  rung 500 (14×14, a ground of windows, neither end pinned) in 0.9–1.7 s. Every template of
  every ground at shapes 2–4 threads on 40 of 40 seeds. The next sixty dailies all prove
  unique at 250,000 nodes and regenerate identically from their seed (worst 2.6 s, measured
  while a Release build ran alongside, so contended). Generation always runs off the main
  actor; the next book pattern and tomorrow's daily are pricked ahead on every lift.
- **The pillow** (Today): the card at −1.2° on the bolster, pins, gimp, windows, the brass
  start and ringed finish, the thread with rings on turns and plaits on runs of four, the
  bobbin, the drag with inner-64 % hysteresis and a step-by-step walk for fast fingers,
  unpick by dragging back or touching an earlier pin (one miss per gesture), dead-end tug and
  crease ring, the plait flash and line, the rising `.step` phrase, run marks, the marking pin
  (press and hold, once earned), the breathing start pin and ghost thread on a fresh pattern,
  "Pull the pins" behind its confirmation, VoiceOver pin grid with tap-to-take.
- **The lift**: phase timeline (tighten wave, pins out, lace lifts with shadow, ghost
  `CountUp` numeral, snips, madder headline, margin card), four tiers from
  `Run.tier(score: longestChain, beating: bestThread)`, gold picot on a best, the ending's
  two lines naming what is waiting. Under `-stillFrames` it lands on the last phase.
- **The play**: `Ladder` exactly as DESIGN.md (`flattensAt` 221), the published week for
  today's pattern, `Mastery<Ground>` written on every lift and read to pick the next book
  ground, `Run` per pattern, `Earned` for seven milestones (silk, marking pin, gold, ticking,
  initials, year cloth), loose work seeded by its own counter.
- **The sampler**, **the book** (stack, chapters, cushion, ledger), **the workbox** (kit
  settings plus counts, sounds, reminder, thread/cover pickers, initials, empty), the paywall
  with the book art and pin-head bullets, onboarding with the three drawn pages.
- The swatch share card (the central 5×5 only, spoils nothing) via `ShareImage`.
- Launch flags: `-onboarded -reset -sampleData -pro -fakeProducts -screen -board -rung/-level
  -wound -fresh -thread -won -demo wind|lift|first -lesson [1|2|3]`.
- `verify-app.sh maze`: 8 screens built, launched and rendered, no crash reports.
- `tells.mjs`: 0 hard tells, 0 smells. Listing files written and inside their limits.
  `products.mjs` flags only the missing review screenshot, which app-shots composes.

## The first card (26 Sep, after the owner's TestFlight pass)

"I had no idea what to do with it." A Saturday install opened on today's pattern, an eleven by
eleven honeycomb medallion of 103 pins, with nothing on screen but a breathing pin. Added, as
DESIGN.md's *The first card* now describes:

- `FirstCard.swift`: three hand-made practice patterns (3×3 lane, 4×4 with forks, 4×4 wound
  into a corner), each proved by brute force to have exactly one way through, and `GhostHand`.
- `Bench`: the lesson over the board (never saved), dead-end coaching with the hand, the
  newcomer's first pattern is the book's first, one-time notes for no brass pin, no ring and
  windows (`Record.taught`, `Record.hints`, both decoded with defaults).
- `PillowView`: the lacemaker's note in the margin, Skip in the toolbar, "The first card
  again" in the menu. `qa.json`: 05-first-pattern now shows card 1; new `first` moment.
- Checked on the simulator: `-demo first` works all three cards through the real take,
  dead-end, unpick and clear paths; after the lesson a fresh record lands on book pattern 1
  (5×5); a record past the lesson with a medallion today gets the window note once; dark mode
  and AX5 hold. `tells.mjs --strict`: 0 hard tells, 0 smells.

## Not checked here

- A real purchase: no runner can complete one.
- Haptics, tones, the reminder firing and the share sheet: wired as DESIGN.md says, felt only
  on a phone in the TestFlight pass.
- `LaceworkTests` (the XCTest target ARCHITECTURE.md names) was not added; the timing and
  determinism proofs were run as a standalone `swift -O` harness instead.
