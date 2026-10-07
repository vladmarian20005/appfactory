# Tallies, launch schedule

Day 0 is the day App Review approves it. Before anything goes out that day, put the App Store
id in `ios/App/AppInfo.swift` (`appStoreID`), swap the landing page's "Coming soon" badge in
`content/site/page.html` for the link, run `node apps/tallies/content/site/build.mjs`, and
republish. Every post below that says [link] wants the App Store URL, not the page.

Posting is manual: the X connector is not authenticated.

| When | What |
| --- | --- |
| Day 0, 09:00 | Landing page live with the App Store link. X post 10 (launch) with video 3. Launch email. |
| Day 0, 12:00 | Reddit r/iosapps (developer post). Product Hunt scheduled for the next morning, 00:01 PT. |
| Day 0, evening | X post 2 with image 01 (the scored stave). Answer every Reddit comment. |
| Day 1 | Product Hunt live; post the maker's first comment at launch. Video 1 ("One number. One banner ad."). |
| Day 2 | X thread (post 5). Video 5 ("Every counter app is a chrome clicker."). Reddit r/SideProject. |
| Day 3 | X posts 1 and 4. Video 2 ("Why does a counter need my email?"). |
| Day 4 | X posts 3 and 6. Video 4 ("Took one too many?"). |
| Day 5 | X posts 7 and 9. r/apphookup only if there is a price change or offer to post. |
| Day 6 | X post 8 with the day-5 / day-500 pair. |
| Day 7 | `/retro tallies` against the day-7 bar. SPEC.md says this one is a pipeline test that ships only if it comes out good enough to want to, so the retro decides whether the kit keeps going or stops here. Repeat whichever hook drew the most replies. |

The press blurb goes to anyone who asks, and with any pitch the owner chooses to send. Nothing
is sent to press automatically.

The videos need converting before day 0 (see `videos.md`, *Recording*: the raw `.mov` files
exist, but this runner had no ffmpeg). If they are not cut by day 0, post the stills instead:
image 01 (the scored stave) in video 3's slot and image 03 (the bench) in video 1's, with the
hook as the post text.
