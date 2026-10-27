# Tidepour, launch schedule

Day 0 is the day App Review approves it. Before anything goes out that day, put the App Store
link on the landing page: swap the "Coming soon to the App Store" badge in
`content/site/page.html` for a link, change the "When can I get it?" answer, run
`node apps/color-sort/content/site/build.mjs`, and let app-content publish it. Every post that
says [link] wants the App Store URL, not the page.

Posting is manual: the X connector is not authenticated.

| When | What |
| --- | --- |
| Day 0, 09:00 | Landing page live with the App Store link. X post 10 (launch, image 01). Launch email. |
| Day 0, 12:00 | Reddit r/iOSGaming (developer post). Product Hunt scheduled for the next morning, 00:01 PT. |
| Day 0, evening | Video 1, "The pour" (X post 6 as its text). Answer every Reddit comment. |
| Day 1 | Product Hunt live; post the maker's first comment at launch. Video 2 ("It gave me a level that can't be won."), X post 1. |
| Day 2 | X thread (post 4). Video 4 ("You start a round, ads."). Reddit r/iosapps. |
| Day 3 | X posts 2 and 9. |
| Day 4 | Video 3 ("Same puzzle, everyone, every day."). X post 8. |
| Day 5 | Video 5 ("Can't tell the colours apart?"), X post 7. Reddit r/colorblind, only if its rules allow a developer feedback post, no link. |
| Day 6 | X posts 3 and 5. |
| Day 7 | `/retro color-sort` against the day-7 bar (100 downloads, 3 paying, rating ≥ 4.5). Then repeat whichever video drew the most replies, with a new hook. |

The press blurb goes to anyone who asks, and with any pitch the owner chooses to send. Nothing
is sent to press automatically.

The clips in `content/clips/` are the footage without captions; burn the on-screen text from
`videos.md` in before posting. If they are not captioned by day 1, post the stills instead —
the win (01) in video 2's slot, the shore (04) in video 4's — with the hook as the post text.
