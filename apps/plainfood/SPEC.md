# Plainfood

Picked 2026-09-08 by the factory's autonomy rule (no owner pick by Monday noon). The scout's
top score was coloring book (79); it was passed over because its wedge is curated art, which
the factory cannot produce at quality in two days. Calorie tracker (75) has the strongest
dissatisfaction signal of the day and its only skip risk, a nutrition database, is covered by
Open Food Facts, a free API that needs no key.

## Promise

Log what you eat in seconds and see your calories and macros without ever hitting a paywall
for the basics. For people who count calories or macros and are tired of apps that move
features behind a subscription every update.

## Wedge

From 100 recent reviews of MyFitnessPal (78 at 3★ or under), the three complaints this app fixes:

1. **Free features keep disappearing.** "Every time I update it they take away a feature that
   used to be free… And $20 a month is a steep price for an app!" → Search, barcode, manual
   entry, daily macros and goals are free forever, stated on the paywall itself.
2. **Macros behind the paywall.** "The most useful view was to see my daily macros. Now it's
   hidden behind the paywall!" → Protein, carbs and fat are on the home screen, free.
3. **Harder to use after redesigns.** "The new UI is way harder to find what I need." → One
   screen for today, one to add food, one for trends. No feed, no social, no ads.

## MVP

Three screens, one core loop: open, add food, see the ring move.

1. **Today** — calorie ring against the daily budget, protein/carbs/fat bars, meals
   (breakfast, lunch, dinner, snacks) with logged items. Tap an item to edit servings or delete.
   Tap the ring to edit goals.
2. **Add food** — search Open Food Facts, scan a barcode (VisionKit on device; manual code entry
   on the simulator), or enter a food by hand. Recent foods first. Pick servings, pick the meal, save.
3. **Trends (Pro)** — 7 and 30 day calorie and macro charts, weekly average against goal, streak.

Plus the kit's Settings screen with goals editing (free), restore, rate, share, support, privacy.

Local-first: SwiftData on device, no account. Network only for food lookups.

## Monetization

Weekly $4.99 and yearly $29.99 subscription, 3-day free trial, through StoreKit 2.
Product ids `com.factory.plainfood.pro.weekly`, `com.factory.plainfood.pro.yearly`.
Pro unlocks Trends and, later, CSV export and widgets. Everything in the loop stays free.

## Needs from the owner

- [ ] Nothing for the build. Open Food Facts needs a descriptive User-Agent, already set.
- [ ] For upload: Apple Developer Program, App Store Connect API key, Team ID.

## Store

- Name: `Plainfood: Calorie & Macro Log` (30)
- Subtitle: `Macros & barcode, always free` (29)
- Keywords: calorie counter, macro tracker, food diary, barcode scanner, nutrition, carb counter,
  protein tracker, weight loss, keto, meal log
- Primary category: Health & Fitness. Secondary: Food & Drink.
- Name check 2026-09-08: no App Store result named Plainfood. "MacroLog" was taken twice and rejected.

## Distinct from the leader

Not a reskin. MyFitnessPal is a social, ad-supported, account-based platform whose model depends
on moving features into Premium. Plainfood has no account, no ads, no feed, and a written promise
on the paywall that logging, barcode and macros stay free. The Pro tier sells analysis, not access.
Data source is Open Food Facts rather than a proprietary database, and everything lives on device.

## Day-7 bar

100 downloads, 3 paying, rating at or above 4.5. The niche median is $94K/mo modeled, so the
bar can rise in week two if the first week clears it.

## Risks

- Open Food Facts coverage is thinner than MyFitnessPal's for US restaurant chains. Manual entry
  and recent foods soften it; a USDA FoodData Central fallback is a week-two option.
- Barcode scanning cannot be tested on the simulator; manual code entry covers the flow.
- Health claims: none made. The app counts what the user logs; no diet advice.
