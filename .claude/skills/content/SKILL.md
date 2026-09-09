---
name: content
description: Write the launch kit for an app: landing page, five short-video scripts with simulator footage, posts, listing, email. Use for "landing page", "posts", "launch content", "content <slug>".
---

# /content <slug>

Requires screenshots and metadata from `/ship`. Output goes to `apps/<slug>/content/` and `the starhiveconcept-site repo's site/<slug>/`.

1. **Landing page.** Rewrite `the starhiveconcept-site repo's site/<slug>/index.html` as a real page: promise, three benefits mirroring the screenshot titles, the composed screenshots, App Store badge (link to the app once it has an id, otherwise "coming soon"), FAQ from the wedge, privacy link. Static HTML and inline CSS only. Render it once with the browse tool and Read the screenshot.
2. **Footage.** For each of five scripts, record 15–25 seconds on the simulator: `xcrun simctl io <udid> recordVideo content/raw/0N.mov` while driving the app, stop with Ctrl-C. Convert to vertical MP4 with ffmpeg (1080x1920, 30 fps). Captions can be burned in later; write the caption timings in the script.
3. **Scripts.** `content/videos.md`: five scripts, each with a hook line under 8 words, a 20–30 second beat list, the shot to show for each beat, and the on-screen text. Hooks come from the leader's complaints, e.g. "MyFitnessPal put macros behind a paywall. This doesn't."
4. **Posts.** `content/posts.md`: ten X posts (mix of one-liners, a thread opener, a before/after), one Reddit post per relevant subreddit written to that subreddit's rules with no link-dropping where forbidden, one Product Hunt listing (tagline ≤60, description, first comment), one launch email, one press blurb.
5. **Schedule.** `content/schedule.md`: what goes out on approval day, day 2, day 7. Posting is manual unless the X connector is authenticated.
6. Update STATUS.md (`stage: content ready`) and commit.
