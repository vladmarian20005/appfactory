# Quizday · plan

Planned 2026-09-09 by `/plan-app trivia`. Evidence: `evidence.json` (niche and top five, modeled), `store-reviews.json` (store-page reviews, "most helpful" sort, because Apple's public feed was empty for all five today), and `reports/scout/2026-09-09.md`.

## 1. Verdict

Build, with one change to the scout's concept. "Ad-light" is not enough: the wedge is zero ads, zero lives or coins, and a loop of our own, one shared ten-question round a day with every answer explained. The deciding number is the leader's recent sentiment: 44 of Trivia Crack's last 50 reviews are 3★ or under (88%), in a field where the median app makes $64K/mo modeled.

## 2. The market

Modeled revenue across the niche is $11M/mo over 43 apps. The top app takes 21%, the median app makes $64K/mo modeled, and the scout grades it "Open field": demand is spread out, no single leader to dislodge, so distribution decides it.

## 3. The top five, torn down

Unhappy share is known only for the leader (50 recent reviews via the scout). The feed was empty for the rest, so the last column counts 3★-or-under among each store page's ten "most helpful" reviews, the store's default sort, not the most recent.

| App | Rating (count) | Modeled $/mo | Price model | Unhappy (feed) | ≤3★ of 10 store reviews |
|---|---|---|---|---|---|
| Trivia Crack: Brain Quiz Games | 4.60★ (747,778) | $2.3M | free, coins $0.99–$24.99, lives $2.99 | 88% of last 50 | 7 |
| QuizTime - Trivia | 4.50★ (60,132) | $1.1M | free, $7.99/wk, $23.99/mo, $79.99/yr, remove ads $1.99 | no feed data | 9 |
| Trivia Star: Trivia Games Quiz | 4.92★ (314,256) | $1.0M | free, VIP $3.99/wk, remove ads $4.99, gems | no feed data | 6 |
| Trivia Crack Retro Brain Games | 4.65★ (285,804) | $920K | free, VIP $1.99/mo, no ads $4.99, packs | no feed data | 8 |
| QuizzLand. Quiz & Trivia game | 4.71★ (221,910) | $710K | free, no ads $2.99–$6.29, infinite lives $1.99–$4.99 | no feed data | 3 |

**Trivia Crack** (Etermax, 2013). Turn-based matches against friends and strangers, mini games, tournaments. Charges through coin and credit packs, a 5 Lives Pack and a Daily Question Premium Pack. Hated: the ad load. "Every time I get a question wrong or go to play a mini game, I have to sit through a long ad that I've seen a million times before." Paying does not fix it: "I actually purchased the full version which you would think would eliminate ads. If anything they got worse." Loved: the facts and the pace. "I love the fast match, makes it easy to just keep playing."

**QuizTime** (Hundred Years, 2019). Picture quizzes with a gift-card reward machine. Charges a Diamond Member subscription, $7.99 a week or $79.99 a year, that removes ads and grants coins, plus coin packs. Hated: "This game averages 12-15 minutes of ad time for 6-8 minutes of actual game time", "it plays an ad after every single question!!!!!". Loved, even inside the complaints: "it is a lot of fun and it keeps me thinking. I also learn fun facts."

**Trivia Star** (Super Lucky Games, 2020). Level-based solo trivia with a gem economy. Charges a $3.99 weekly VIP, a $4.99 remove-ads unlock and gem packs. Hated: "I just don't like how EVERYTHING costs of gems, or coins." and "a 30+ second Ad after EACH very short set of 3 questions." Loved: the ramp and the variety. "starts off easy and gets more challenging and has multiple fun trivia categories".

**Trivia Crack Retro** (Etermax, 2018). The sequel: more modes, events, duels. Charges a $1.99 monthly VIP, a $4.99 no-ads unlock, packs and gold chests. Hated: "There is an ad on your screen at all times, including full screen pop up's occasionally.", paying for lives, and "questions that have completely wrong answers but you can't flag them". Loved: the modes, and silence once paid. "one of the few games I don't mind paying for, so I never see ads".

**QuizzLand** (MNO GO APPS, 2018). Levels of 21 questions, three difficulties, an explanation after each answer, leaderboards. Charges no-ads unlocks ($2.99 to $6.29) and infinite-lives passes ($1.99 to $4.99). Same two complaints: "I answer 4 or 5 questions…ad…a few more questions…ad, etc. Wasn't that way originally." and "incorrect answers or completely no correct answer choice". Loved: what the others lack. "I like the explanations to each answer at the end." and "great diversity of questions compared to other games I've played".

## 4. The wedge

Three complaints we fix:

1. **Ads between every action.** Named in all five apps, including by people who paid ("If anything they got worse"). Quizday has no ad SDK at all, and the paywall says so.
2. **Lives, coins and pay-to-continue.** "100 coins (or gems) JUST to CONTINUE??" (Trivia Star); "a total rip off to have to pay to get more lives" (Retro). Quizday has no currency and nothing to run out of.
3. **Wrong answers with no way to flag them.** Carried by four of the five. Every Quizday question ships with a one-line explanation, a source, and a report button on the reveal.

Two things we must match: variety across categories ("great diversity of questions", "multiple fun trivia categories") and an explanation after every answer, QuizzLand's most-loved feature.

One thing we skip: multiplayer. Challenging friends is Trivia Crack's core and needs accounts and a backend; the shared daily round gives people something to compare without it.

## 5. The product

Three screens.

1. **Today.** The day's ten questions, the same ten for everyone that day. One at a time, four answers, instant reveal with explanation and source. No timer, no lives.
2. **Scorecard.** Score out of ten, current streak, the month as a calendar of played days, share as a plain text line, and the reminder toggle.
3. **Practice (Pro).** Pick a category and difficulty, play unlimited rounds, see accuracy per category.

Plus the kit's Settings and paywall. Local-first, no account.

v1.1: monthly question packs as a static JSON file on the app's GitHub Pages site (no backend), and a Pro archive of past dailies.
v1.2: a home screen widget with today's status and streak.

| Free, forever | Pro |
|---|---|
| The daily ten, explanations and sources, streak, calendar, share, reminder, zero ads | Unlimited practice by category and difficulty, per-category accuracy, archive of past dailies, alternate icons |

## 6. Data and dependencies

- **Question pack (bundled).** 300 original questions, 30 rounds, each with an explanation and a source, written and fact-checked during the build. The date picks the round deterministically, so every player gets the same ten with no server. No key; no questions copied from any app.
- **Open Trivia Database (Pro practice).** Free, no key, CC BY-SA 4.0 with attribution in Settings. Network only inside Practice.
- **Device.** Local notifications for the reminder, haptics from the kit, the share sheet.
- **Flags.** Today's report shows none (buildability 1.0); the scout code committed later this morning counts trivia as a game, costing 0.4, for art, levels and tuning. Quizday has none of those; it is a ritual like a daily crossword.
- **Owner keys.** None for the build. App Store Connect key and Team ID for upload, as with Plainfood.

## 7. Name and store

| Candidate | App Store search, 2026-09-09 |
|---|---|
| **Quizday** (picked) | No app of that name. Nearest results: QuizTime, 100 PICS Quiz, Facts - Daily Random Trivia. |
| Quiet Quiz | No app of that name. Nearest: "Quiz Time Triva" (Brightika), "Hardest Quiz Ever!". |
| Plainquiz | Zero results. |

Risk: search adjacency to QuizTime; the subtitle separates us.

- Name: `Quizday: Daily Trivia, No Ads` (29)
- Subtitle: `Ten questions a day. No ads.` (28)
- Keywords: daily trivia, trivia quiz, quiz game, general knowledge, ad free trivia
- Primary: Games (Trivia). Secondary: Education.
- Screenshots: "Ten questions. Every day. No ads." · "Every answer explained." · "Keep the streak. Share the score."

## 8. Money

| | Weekly | Yearly | One-time |
|---|---|---|---|
| QuizTime | $7.99 | $79.99 | remove ads $1.99 |
| Trivia Star | $3.99 (VIP) | | remove ads $4.99 |
| Trivia Crack Retro | $1.99/mo (VIP) | | no ads $4.99 |
| QuizzLand | | | no ads $2.99–$6.29 |
| **Quizday Pro** | **$2.99** | **$19.99** | none |

Three-day free trial, StoreKit 2, product ids `com.factory.quizday.pro.weekly` and `com.factory.quizday.pro.yearly`. We cannot sell "remove ads", the field's most common unlock, because there are none; Pro sells depth.

## 9. Build plan

Next factory week, 14–18 September. If the go comes today, Thursday and Friday become build days and QA moves to Monday.

- **Mon 14, spec.** This plan is the spec. Write the question-pack brief: 30 rounds, category mix, difficulty ramp inside each round.
- **Tue 15, build.** `/new-app quizday "Quizday"`. Today and Scorecard, the date-seeded round picker, streak logic, the first 150 questions. Owner: read a 50-question sample, reject anything doubtful.
- **Wed 16, build.** Practice with OpenTDB, per-category accuracy, paywall, reminder, share text, the remaining 150 questions. `/ios-qa`, `/ios-design-review`, `/ios-fix`.
- **Thu 17, QA and ship.** `/ship`: screenshots, metadata, fastlane upload, submit. Owner: a real-iPhone test (reminder, haptics, share sheet), the App Store Connect key in the shell, the submit approval.
- **Fri 18, content.** `/content`: landing page and launch kit. Owner: pick the launch posts.

## 10. Risks

- **App Review 4.3 (reskin).** Trivia is a template genre. The answer: a mechanic none of the five has (one shared daily round, no economy), an original pack, and Pro features that are real features, with a paywall promise Apple can read: no ads, ever, nothing to run out of.
- **Content gaps.** 30 rounds run out on day 31; v1.1's pack file ships before then. A wrong answer in our pack is the complaint we campaign on, so every question carries a source and a report button.
- **Copyable in a week.** Etermax already sells a Daily Question Premium Pack and could add a daily mode, but cannot copy the no-ads, no-lives promise without giving up its revenue model.
- **Game flag.** Screenshots of a quiz look like every quiz. The first screenshot shows the calendar and the streak, not a question card.

## 11. Success and kill

- **Day-7 bar:** 100 downloads, 3 paying, rating 4.5+ (the default).
- **Four-week kill rule:** stop new work if by day 28 it has under 500 downloads, under 15 paying, or under a quarter of day-1 players back on day 2. Keep it live either way.
- **The one daily metric:** daily rounds completed by returning players. The product is the ritual; if people come back for tomorrow's ten, everything else follows.
