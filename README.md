# Anime Detour

The official Anime Detour iOS application.

## Requirements

The app is written in Swift 3.1. Xcode 8.3 or later is required to compile it.

## Building

Note that the app does not build without modification after checkout. To make the app buildable, following the [Analytics](#Analytics) instructions to enable or disable usage analytics.

### Analytics

The app uses Google Analytics. Follow Google's documentation on Google Analytics and Firebase to setup Google Analytics and Firebase (without Firebase analytics) in a single configuration `GoogleService-Info.plist` file.

## Deployment

Before deploying, increment the build number of the app by one. Open `Anime Detour.xcworkspace` in Xcode, select the `Anime Detour` project in the Navigator pane, select the `Anime Detour` target in the main editor, and change the build number.

Use [fastlane](https://github.com/fastlane/fastlane) to manage metadata, including the App Store description and screenshots. All `fastlane` commands should be run from the root of the repo. See `fastlane/README.md` for installation instructions and helpful links.

### Betas

Run `fastlane beta` to make and deploy a TestFlight beta build.

### Releases

Run `fastlane appstore` to make and deploy an app store release build.

## License

The application may be distributed under the terms of the Apache 2.0 license. See `LICENSE.md` for details. Some assets are covered under different licenses, detailed in `NOTICE.md`.
