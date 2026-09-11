One folder per app. Created by `/pick`, directed by `/direct`, filled by `/new-app`,
judged by `/critique`, finished by `/polish`, `/ship`, `/content`.

```
<slug>/
  SPEC.md          promise, wedge, MVP screens, monetization, store fields, day-7 bar
  DESIGN.md        the idea, look, signature interaction, reward, voice, tokens (/direct)
  design/          icon.svg + icon-1024.png, art/*.svg, mock-*.html + their PNGs
  CRITIQUE.md      the latest critic's verdict against TASTE.md, with design-score.json
  STATUS.md        stage: picked | built | submitted | live | stopped, with dates
  ios/             XcodeGen project (project.yml + App/), depends on ../../../FactoryKit
  store/
    raw/           simulator captures, 1290x2796
    screenshots/   composed App Store screenshots
    metadata/      fastlane deliver layout (en-US/name.txt, subtitle.txt, keywords.txt, ...)
  content/         videos.md, posts.md, schedule.md, raw footage
```
