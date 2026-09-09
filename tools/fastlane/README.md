fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

## iOS

### ios check

```sh
[bundle exec] fastlane ios check
```

Read-only: verify the API key, list the team's apps, warn on an expiring certificate

### ios create

```sh
[bundle exec] fastlane ios create
```

Create the app record in App Store Connect (APP_NAME, BUNDLE_ID)

### ios beta

```sh
[bundle exec] fastlane ios beta
```

Archive with a distribution profile and upload to TestFlight

### ios release

```sh
[bundle exec] fastlane ios release
```

Push metadata, screenshots and privacy answers, then submit the latest build for review

### ios certprobe

```sh
[bundle exec] fastlane ios certprobe
```



----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
