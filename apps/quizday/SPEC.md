# Quizday

Planned 2026-09-09 by `/plan-app trivia`. Full plan with evidence in `PLAN.md`; this is the compression `/new-app` reads.

## Promise

Ten trivia questions a day, the same ten for everyone, every answer explained, and never an ad or a life to buy. For people who like a daily brain ritual and have deleted trivia apps over ads.

## Wedge

From the leader's last 50 reviews (44 at 3★ or under, scout 2026-09-09) and the ten most helpful store reviews of each of the top five:

1. **Ads between every action.** "Every time I get a question wrong or go to play a mini game, I have to sit through a long ad that I've seen a million times before." (Trivia Crack). Even paying does not stop it: "I actually purchased the full version which you would think would eliminate ads. If anything they got worse." → No ad SDK in the app. The paywall says so.
2. **Lives, coins and pay-to-continue.** "I just don't like how EVERYTHING costs of gems, or coins." (Trivia Star); "it is a total rip off to have to pay to get more lives in order to play anymore games" (Trivia Crack Retro). → No currency, nothing runs out.
3. **Wrong answers you cannot flag.** "There are questions that have completely wrong answers but you can't flag them" (Trivia Crack Retro); "in some cases I have found the app to be wrong!!" (Trivia Star). → Every question has an explanation, a source, and a report button on the reveal.

Match what they love: category variety ("great diversity of questions", QuizzLand) and an explanation after every answer ("I like the explanations to each answer at the end", QuizzLand).

## MVP

Three screens, one loop: open, play today's ten, see the streak, come back tomorrow.

1. **Today** — the day's ten questions, picked deterministically from the date so everyone gets the same ten. One question at a time, four answers, tap to answer, instant reveal with a one-line explanation and source, a report button, next. No timer, no lives, no ads. Ends in the Scorecard. Once played, Today shows the result and the countdown to tomorrow.
2. **Scorecard** — today's score out of ten, current streak, the month as a calendar of played days with scores, share as a plain text line (ten squares plus the score), daily reminder toggle (local notification).
3. **Practice (Pro)** — pick a category and difficulty, unlimited rounds from the Open Trivia Database, per-category accuracy so weak spots are visible.

Plus the kit's Settings (restore, rate, share, support, privacy, OpenTDB attribution) and the paywall with the promise: no ads, ever; nothing to run out of.

Content: a bundled JSON pack of 300 original questions (30 rounds × 10) with `question, answers[4], correct, explanation, source, category, difficulty`. Written and fact-checked during the build; copy none from any app. Rounds ramp from easy to hard within the ten.

Local-first: `@AppStorage` for streak and settings, SwiftData for round results. Network only inside Practice.

## Monetization

Weekly $2.99 and yearly $19.99 subscription, 3-day free trial, StoreKit 2.
Product ids `com.factory.quizday.pro.weekly`, `com.factory.quizday.pro.yearly`.
Pro unlocks Practice, per-category accuracy, and (v1.1) the archive of past dailies. The whole daily loop stays free with no ads.

## Needs from the owner

- [ ] Nothing for the build. OpenTDB needs no key.
- [ ] Tuesday: read a 50-question sample of the pack and reject anything doubtful.
- [ ] Thursday: a real-iPhone test (reminder fires, haptics, share sheet), then the submit approval.
- [ ] For upload: Apple Developer Program, App Store Connect API key, Team ID.

## Store

- Name: `Quizday: Daily Trivia, No Ads` (29)
- Subtitle: `Ten questions a day. No ads.` (28)
- Keywords: daily trivia, trivia quiz, quiz game, general knowledge, ad free trivia, brain, facts, quiz of the day, trivia questions, streak
- Primary category: Games (Trivia). Secondary: Education.
- Name check 2026-09-09: no App Store app named Quizday; nearest results QuizTime and Facts - Daily Random Trivia. "Quiet Quiz" and "Plainquiz" were also clear and rejected.

## Distinct from the leader

Not a reskin. Trivia Crack is a social, ad-supported, account-based match game whose revenue comes from coins, lives and ads. Quizday has no account, no ads, no currency and no multiplayer. Its mechanic, one shared ten-question round a day with a calendar and a streak, exists in none of the top five. The content pack is original and every question carries a source. Pro sells practice and stats, not access to the loop.

## Day-7 bar

100 downloads, 3 paying, rating at or above 4.5. The niche median is $64K/mo modeled, so the bar stays at the default. Four-week kill rule and the daily metric are in PLAN.md §11.

## Risks

- App Review 4.3: trivia is a template genre. Answered by the daily-round mechanic, the original pack, and real Pro features; the first screenshot shows the calendar and streak, not a question card.
- Content: 30 rounds run out on day 31. v1.1 ships a static monthly pack file from the app's GitHub Pages site before then. No backend.
- Licensed content, regulated claims, hardware: none. Network: none in the free loop. Game flag: the scout now counts trivia as a game (costs 0.4 buildability); there is no art, level or tuning work in this MVP.
