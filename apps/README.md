One folder per app. Created by `/pick`, filled by `/new-app`, `/ship`, `/content`.

```
<slug>/
  SPEC.md          promise, wedge, MVP screens, monetization, store fields, day-7 bar
  STATUS.md        stage: picked | built | submitted | live | stopped, with dates
  ios/             XcodeGen project (project.yml + App/), depends on ../../../FactoryKit
  store/
    raw/           simulator captures, 1290x2796
    screenshots/   composed App Store screenshots
    metadata/      fastlane deliver layout (en-US/name.txt, subtitle.txt, keywords.txt, ...)
  content/         videos.md, posts.md, schedule.md, raw footage
```
