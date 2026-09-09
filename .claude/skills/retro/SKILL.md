---
name: retro
description: Weekly review of a published app against its day-7 bar; decide keep, iterate, or stop. Use for "how is <app> doing", "retro".
---

# /retro [slug]

1. For each app in `apps/*/STATUS.md` with `stage: submitted` or later, gather: App Store status, rating and rating count from `GET /api/v1/public/app/ios/<id>` on the local site (track the app there first), the last 50 reviews via `src/lib/reviews.ts`, and downloads and proceeds from App Store Connect if `ASC_*` keys exist (`fastlane run download_sales_reports` or the Sales Reports API).
2. Compare with the Day-7 bar in SPEC.md. Write `apps/<slug>/RETRO-<date>.md`: numbers, the three most useful review quotes, what the scout says about the niche now, and one of three verdicts: **keep** (on track), **iterate** (a v1.1 with the top complaint fixed takes this week's slot), **stop** (four weeks under the bar; no more time).
3. Append the verdict to STATUS.md and give the owner a five-line summary. If the verdict is iterate, write the v1.1 scope as a new section in SPEC.md.
