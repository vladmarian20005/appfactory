# Thousand

Planned 2026-09-12 from [issue #5](https://github.com/vladmarian20005/appfactory/issues/5) by the
build-request procedure. Full plan with evidence is private, in appmonkey
`plans/language-drills/PLAN.md`; this is the compression `app-build` reads. All revenue figures are
**modeled**.

## Promise

A thousand Spanish words, in the order you actually meet them, drilled by a scheduler that
remembers what you forget. Bought once, works on a plane, and it never guilts you about a streak.
For people who want vocabulary they keep, not a subscription and a cartoon owl.

## Wedge

Apple's review feed returned nothing for all five top apps this run (`feedEmpty: true`,
`reviewsSampled: 0` for Duolingo, Babbel, Rosetta Stone Classic, Memrise, EWA), so there are **no
complaint quotes behind this spec**. The wedge is built from what the competitors sell, in their
own store descriptions, and from the shape of the market.

1. **Every competitor rents.** All five top apps are free-to-install and subscription-funded;
   Rosetta Stone Classic now exists only "for current Rosetta Stone Classic subscribers". This app
   has no server, no AI and no licensed content, so nothing has to be rented. **One-time $9.99.**
2. **Gamification is the incumbent's whole pitch, and the split is already live.** Duolingo sells
   "the fun, free app … bite-sized lessons … And now, you can learn CHESS on Duolingo!"; Memrise
   markets against it ("Unlike gamified apps with robotic voices…"). We take the far end: **no
   streak, no lives, no cartoon pressure.** A missed day costs nothing.
3. **One language, finished, beats forty started.** Duolingo sells 40+ languages, Memrise 136+,
   Mondly 41. Lingvano sells exactly one (sign language) and makes $480K/mo modeled at 4.88★ over
   116,297 ratings; Teuida is Korean-first at 4.89★. Depth in one is both the better product and
   the only content scope a two-day build finishes well.

Match what the field sells: **pronunciation on every word** (Memrise sells native-speaker video,
Babbel sells an AI partner, EWA sells audio books) and correctness.

Deliberately skip: speaking practice and AI conversation. That is where Babbel Speak, Praktika,
Speak and Falou went, and it is a recurring bill. Pronunciation comes from `AVSpeechSynthesizer`
on the device — free, offline, no key.

## MVP

Three screens, one loop: open, drill what is due, watch it shrink.

1. **Drill** — the session. One card at a time: the Spanish word, tap to reveal English plus an
   example sentence and its translation, then grade *again / good / easy*. A local SM-2 style
   spaced-repetition schedule sets the next appearance. A speaker button reads the word with
   `AVSpeechSynthesizer` (`es-ES`). When nothing is due it says so and stops — it must never invent
   work to fill a session.
2. **Deck** — all 1,000 words grouped into themes, searchable, each row showing its state (new,
   learning, known). Tap any word for its card. Free opens the first 100 words and 2 themes.
3. **Progress** — words known, words learning, what is due today and tomorrow, mastery per theme.
   **No streak and no calendar of missed days** — that absence is the product, not an omission.

Plus the kit's Settings (restore, rate, share, support, privacy) and a paywall stating the promise:
bought once, works offline, no subscription.

Content: a bundled JSON pack of **1,000 common Spanish words for English speakers**, written during
the build, each entry `word, translation, example, exampleTranslation, theme, rank`, ordered by
frequency band and grouped into ~12 themes. Common-core vocabulary only — where correctness risk is
lowest. Every example sentence must agree with its own translation. Copy nothing from any app.

Local-first: SwiftData for card state, `@AppStorage` for settings. **No network at all**, so the
privacy manifest collects nothing.

v1.1: a second language pair. v1.2: your own cards.

## Monetization

**One-time unlock, $9.99, no trial.** Product id `com.factory.language-drills.pro`, StoreKit 2.
Free: the drill, the scheduler, speech, progress, the first 100 words, 2 themes. Pro: all 1,000
words and all themes. No ads, ever. No subscription — that is the wedge, and the paywall says so in
those words.

## Needs from the owner

- [ ] Nothing for the build. No key, no account, no API.
- [ ] Before any release: spot-check a sample of the deck and reject anything doubtful.
- [ ] A real-iPhone pass (speech works, haptics, restore purchase), then the submit approval.
- [ ] For upload: Apple Developer Program, App Store Connect API key, Team ID.

## Store

- Name: `Thousand: Spanish Vocabulary` (28)
- Subtitle: `1,000 words. Bought once.` (25)
- Keywords: spanish vocabulary, learn spanish, flashcards, spaced repetition, offline spanish, no subscription, word drill, spanish words, srs, study spanish
- Primary category: Education. Secondary: Reference.
- **App Store collision not checked** — no App Store search in the build sandbox. "Wordbank" and
  "Lexika" were the other candidates; none matches an app in the evidence.
- Screenshot captions: "1,000 words, in order of use" · "It remembers what you forget" · "Buy it
  once. Keep it."

## Distinct from the leader

Not a reskin. Duolingo is a gamified, subscription, 40-language course app with streaks, lives and
now chess. This is a single-language spaced-repetition vocabulary trainer, bought once, fully
offline, with no streak and no currency. The top five are course apps; this is a flashcard app —
a different category of product, not a restyling of theirs. 4.3 exposure is low.

## Day-7 bar

100 downloads, 3 paying, rating at or above 4.5. The niche median is $98K/mo modeled, so the bar
stays at the default. Four-week kill rule and the daily metric are in PLAN.md §11.

## Risks

- **Newcomers are not breaking into this niche.** The two youngest apps the scout found make $14K
  and $2.5K/mo modeled (Language Learning - Easy Speak, 436 days; Wordletic, 170 days). This is the
  strongest argument against the idea and nothing in the evidence answers it. It is the kill
  criterion: if month one lands nearer $2.5K than the $98K median, stop at one language.
- **Correctness.** A wrong translation is worse than a wrong trivia answer. Common-core vocabulary
  only; every example must agree with its translation; the owner spot-checks before release.
- **Synthesised voice.** Memrise attacks exactly this ("robotic voices"). We accept weaker
  pronunciation to avoid a recurring bill; first thing to revisit if reviews punish it.
- **No feed data.** Apple returned no reviews for any of the five leaders, so this spec rests on
  store descriptions, ratings and modeled revenue only.
- Licensed content, regulated claims, hardware, backend, network: none. Buildability 1.0, no flags.
