---
name: aso
description: Write the App Store listing for every localization Apple indexes on the US storefront. Use for "/aso <slug>", "localize the listing", "cross-localization keywords".
---

# ASO for the US storefront, in ten languages

Apple indexes the metadata of ten localizations when someone searches the **US** App Store:
English (US) and the nine in `tools/aso/locales.json`. Each extra localization is another
30-character name, 30-character subtitle and 100-character keyword field that ranks in US
search. Screenshots are not needed: App Store Connect shows the primary language's
screenshots for a localization that has none.

The English listing in `apps/<slug>/store/metadata/en-US/` is the source. This skill writes
the other nine. Never change en-US here.

## Read first

`apps/<slug>/SPEC.md` (the Promise and the Wedge), `apps/<slug>/store/metadata/en-US/*`,
and, if present, `apps/<slug>/evidence.json` and `apps/<slug>/store-reviews.json` for the
words real users use for this kind of app. `tools/aso/locales.json` is the list.

## What each localization gets

Write the text in that language, as a native speaker who sells apps would, not as a
translator. The claims are exactly the English claims: if en-US says no ads, no account,
no tracking, say that and nothing more. A promise the binary does not keep is a rejection.

- **name** (30): the brand word from en-US (the part before the colon) stays as it is, in
  Latin letters, in every language; the rest is the app's promise in that language's most
  searched phrasing. Not a literal translation of the English name.
- **subtitle** (30): the wedge, in that language.
- **keywords** (100): comma-separated, no space after the comma, all lower case, no term
  that appears in that localization's name or subtitle. This field exists to widen **US**
  coverage, so most of it is **English** long-tail terms the en-US listing does not use —
  synonyms, spellings, the phrases from reviews — plus three or four native-language terms
  a speaker of that language living in the US would type. Never repeat a term across the
  nine localizations; the tenth copy of "quiz" buys nothing. No competitor names, no other
  app's brand, no category names Apple already assigns ("games", "utilities").
- **promotional_text** (170) and **description** (4000): the English ones, rewritten in that
  language with the same structure and the same claims. Keep prices in US dollars exactly as
  en-US states them; keep the subscription terms paragraph if en-US has one.
- **release_notes**: the en-US notes in that language.

privacy_url and support_url are copied from en-US by the writer script; do not write them.

## How to write them

Put every localization in one JSON file, then let the script write the files and count the
characters:

```
node tools/aso/write-locales.mjs apps/<slug>/store/metadata /tmp/listing.json
.github/scripts/listing-check.sh <slug>
```

`listing.json` is `{ "<code>": { "name", "subtitle", "keywords", "promotional_text",
"description", "release_notes" }, ... }`, codes as in `tools/aso/locales.json`. The limits
are in characters; the check counts characters, so Chinese and Arabic are not penalised.
Fix every error and every warning the check prints, then run it again until it is clean.

Do not commit or push. The workflow that runs this skill commits the metadata directory
when the check passes.
