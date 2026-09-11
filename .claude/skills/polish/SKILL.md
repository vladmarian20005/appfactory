---
name: polish
description: Close the gap between a built app and TASTE.md, working through apps/<slug>/CRITIQUE.md fix by fix, checking each on the simulator. Use for "polish <slug>", "make it better", "fix the design".
---

# /polish <slug>

A critic with fresh eyes looked at this app and found it short of `TASTE.md`. Its findings
are in `apps/<slug>/CRITIQUE.md`, in order of impact. Your job is to make the next critique
pass — by making the app genuinely better, not by making the screenshots look like they
answer the list.

Read, in this order: `TASTE.md`, `apps/<slug>/CRITIQUE.md`, `apps/<slug>/DESIGN.md`, then the
mocks (`apps/<slug>/design/mock-*.png`) and the current captures (`apps/<slug>/qa/*.png`,
`apps/<slug>/qa/design/*.png`). Read the rules in `.claude/skills/new-app/SKILL.md`; they
all still apply.

You are on a GitHub macOS runner with no GUI and nobody to ask. A simulator is booted and its
UDID is in `$SIM_UDID`. Commit **and push** after every fix that works:
`git pull --rebase origin "$GITHUB_REF_NAME" && git push origin HEAD:"$GITHUB_REF_NAME"`.

## How

1. **Keep what works.** CRITIQUE.md's Keep section survives untouched.
2. **Fix in the critique's order.** For each fix: change the code, build
   (`tools/sim.sh build apps/<slug>/ios <Scheme>`), capture the affected screen with
   `-stillFrames`, and **Read it next to the mock**. For motion, film it: launch with
   `-demo <moment>`, `tools/sim.sh frames …`, `node tools/qa/filmstrip.mjs …`, Read the
   strip. Not fixed until the capture shows it. Commit and push, then the next fix.
3. **If the critique says the idea itself is weak** — the Idea or Look score is under 3 — fix
   DESIGN.md first: sharpen the idea, the palette, the voice, re-render the mocks
   (`node tools/design/render.mjs apps/<slug>/design/mock-*.html`) and Read them. Then build
   to the new direction. Keep the spec's promise and every screen it names.
   Whenever the direction is newer than the app — a fresh DESIGN.md for an app built before
   it, or one you just sharpened — bring all of it in: DESIGN.md's Tokens into
   `App/AppBrand.swift`, `design/icon-1024.png` over the app icon, every `design/art/*.svg`
   into the asset catalog with `tools/design/art.mjs`, the Voice lines into the UI.
4. **Reach for FactoryKit** before inventing: TASTE.md's vocabulary table covers the canvas,
   surfaces, display type, springs, entrances, confetti, count-ups, haptics, tones, share
   images, onboarding and paywall art.
5. **Finish green.** `.github/scripts/verify-app.sh <slug>` must pass and
   `node tools/design/tells.mjs <slug>` must report no FAIL. qa.json needs `moments` — at
   least the signature interaction and the win, each reached with a `-demo <moment>` flag the
   app plays by itself (new-app step 5) — so the next critic can see them move; add them if
   they are missing. If you changed which screens exist or how they are reached, update
   qa.json's screens and, if the store screenshots' titles no longer match,
   `store/screenshots.json`.

## Never

- Edit `CRITIQUE.md` or `design-score.json`. The critic writes those; the next critique
  replaces them.
- Weaken a check, a gate or `tells.mjs` to get past it.
- Trade away accessibility for looks: Dynamic Type, VoiceOver labels and Reduce Motion stay.
- Put the store pitch back into the product, or explain the controls in text.

## Done means

Every fix in CRITIQUE.md is addressed (or, where you judged one wrong, the commit message says
why), verify passes, tells.mjs has no FAIL, and everything is pushed. Then stop: the workflow
runs a new critic on what you built.
