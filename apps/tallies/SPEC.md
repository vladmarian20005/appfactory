# Tallies

Pipeline smoke test, 2026-09-10. The first end-to-end run of `app-build` with an agent on a
macOS runner. Deliberately small: no network, no permissions, no date seeding, so every
screen is deterministic to screenshot and any failure is the pipeline's fault, not the app's.

## Promise

Count anything, on your phone, without an account. Tap to add, tap to take away, and see
what the week looked like. No sign-in, no sync, no ads.

## Wedge

The counter apps on the store are either a single number on a beige screen with a banner ad,
or a habit tracker that wants an account before it will count to three. Tallies is neither:
several counters, a history you can actually read, and nothing to log into.

## MVP

Three screens, one loop: open, tap a counter, see the history.

1. **Counters** — a list of the user's counters, each a card with its name, its current
   value, and a large `+` that increments with a haptic tap. Swipe to delete. A `+` in the
   toolbar adds a counter (name, a colour from a fixed palette, an optional daily goal).
   Empty state when there are none: one line of copy and a button that creates the first one.
2. **Counter detail** — the count, big; `+` and `−`; the goal ring if a goal is set; and the
   last 14 days as a bar chart built from the entries. Reset today, or reset everything,
   both behind a confirmation.
3. **History (Pro)** — every entry across every counter, newest first, grouped by day, with
   a per-counter total for the week and the month.

Plus the kit's Settings (restore, rate, share, support, privacy) and the paywall.

Free: up to 3 counters, and the last 7 days of history on the detail screen.
Pro: unlimited counters, the History screen, and the full 14-day chart.

SwiftData for counters and entries, `@AppStorage` for settings. No network at all.

## Monetization

Weekly $2.99 and yearly $19.99 subscription, 3-day free trial, StoreKit 2.
Product ids `com.starhiveconcept.tallies.pro.weekly`, `com.starhiveconcept.tallies.pro.yearly`.

## Needs from the owner

- [ ] Nothing. This one exists to prove the pipeline runs unattended.

## Store

- Name: `Tallies: Simple Counter` (24)
- Subtitle: `Count anything. No account.` (27)
- Keywords: counter, tally counter, click counter, count things, tally, habit counter, daily counter, simple counter, count tracker, no ads
- Primary category: Utilities. Secondary: Productivity.

## Distinct from the leader

Not a reskin of anything in this repo. Quizday is a daily trivia round with a bundled
content pack and a network-backed practice mode; Tallies has no content, no network and no
daily reset. They share only FactoryKit, which is the point of a kit.

## Day-7 bar

This is a pipeline test, not a launch. It ships only if it comes out good enough to want to.
