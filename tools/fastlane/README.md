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

### ios certs

```sh
[bundle exec] fastlane ios certs
```

ONE-TIME, LOCAL ONLY: create the Apple Distribution certificate and write its .p12

### ios create

```sh
[bundle exec] fastlane ios create
```

Register the bundle id and create the app record (APP_NAME, BUNDLE_ID)

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

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
