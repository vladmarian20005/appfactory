# Thousand, launch schedule

Thousand isn't on the App Store yet. The `submit` stage passed on 12 September 2026, but the
iTunes lookup for `com.starhiveconcept.thousand` returned nothing on 27 October 2026. So
**approval day** below means the day the app goes live and the owner approves this kit. Nothing
is posted before then: a post with no store link sells a page nobody can act on.

Posting is manual. The X connector isn't authenticated on the runner, and Reddit and Product
Hunt have no connector at all. Every post is in `posts.md`, every clip in `content/clips/`,
every image in `store/screenshots/en-US/`.

**Before anything goes out:**
1. Open the App Store link on a phone and check it resolves and shows $9.99 for the unlock.
2. Set `appStoreID` in `ios/App/AppInfo.swift` for the next build, so the app's rate and
   share rows point at the real page.
3. In `content/site/page.html`, replace the "Coming soon on the App Store" badge with a link
   to the store page. Run `node apps/language-drills/content/site/build.mjs`, then republish.
4. Paste the store URL into every **[App Store link]** in `posts.md`.
5. Check the landing page is live at its published URL.

## Approval day

| When (owner's morning) | Where | What |
| --- | --- | --- |
| 08:00 | X | Thread (post 5) with clip 01 and screenshots 03, 02, 06, 07. Pin it. |
| 08:15 | Email | Launch email to the list. |
| 09:00 | r/iosapps | The [Dev] post. Stay for two hours and answer every comment. |
| 13:00 | X | Post 2, with clip 01 (the turn). |
| 18:00 | X | Post 1, with screenshot 03. |
| any | TikTok / Reels / Shorts | Clip 01, captioned per `videos.md`. |

Product Hunt doesn't go out on approval day. It needs a weekday 00:01 PT start and an owner
who's awake to answer for the first four hours, so it's on day 2.

## Day 2

| When | Where | What |
| --- | --- | --- |
| 00:01 PT | Product Hunt | Listing live, maker's first comment posted right away. Gallery: screenshots 01–04, clips 01, 02, 04. |
| 08:00 | X | Post 6, with clip 02 (the wall grows), linking the Product Hunt page. |
| 12:00 | r/learnspanish | The word-list post. **No link** unless the sidebar allows one. The point is the list, and the feedback on it. |
| 17:00 | X | Post 3, with clip 03 (no streak). |
| any | TikTok / Reels / Shorts | Clip 02. |
| any | Press | Press blurb to two or three writers or newsletters who cover indie iOS apps or language learning. One email each, no follow-up before day 7. |

## Day 7

| When | Where | What |
| --- | --- | --- |
| 08:00 | X | Post 7 (before/after), with screenshot 06. |
| 12:00 | r/languagelearning | Only if a self-promotion thread is running that week; otherwise skip. |
| 17:00 | X | Post 9, with screenshot 05. |
| any | TikTok / Reels / Shorts | Clip 04 (bought once). |
| — | Retro | Day-7 bar check: 100 downloads, 3 paying, rating at or above 4.5 (SPEC.md). Run `/retro language-drills`. |

Clip 03 goes out on day 4 and clip 05 on day 9, on all three short-video apps on the same day.
The link goes in the bio, never in the video.

## Reserve

Posts 4, 8 and 10, and clip 05 on X, are the reserve. Use them after day 7, one every two or
three days, or as a reply in a thread where one fits. Post 10 is a question: answer every
reply to it.

## Don't

- Don't post the same text to two subreddits on the same day.
- Don't post a competitor's screenshot or name a competitor in a hook.
- Don't quote any revenue figure. If one ever appears, it's **modeled**, and it says so.
- Don't call the voice "native audio". It's the iPhone's own synthesised Castilian voice.
- Don't promise a second language, or its price, by a date.
