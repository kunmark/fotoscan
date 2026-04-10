# GitHub Actions iOS Build

## Included workflow

- `.github/workflows/ios-build.yml`

## Purpose

This workflow is a compile and test check for the native iPad app.

It is intentionally configured to:

- run on `macos-latest`
- build the Xcode project from `source/native-ios/BarcodeCaptureApp.xcodeproj`
- use the `BarcodeCaptureApp` scheme
- compile for `iOS Simulator`
- select an available iPad simulator dynamically
- disable code signing with `CODE_SIGNING_ALLOWED=NO`
- run XCTest using the native test target
- upload the `.xcresult` bundle as an artifact

That makes it suitable for early CI verification without Apple signing secrets.

## What it validates

- Xcode project structure is readable by `xcodebuild`
- Swift source compiles on the GitHub macOS runner
- Basic iOS SDK compatibility issues are caught early
- Native XCTest logic tests execute on an iPad simulator
- Test result bundles are available for later inspection

## What it does not do

- real-device signing
- archive creation
- IPA export
- App Store / TestFlight deployment

## How to use

1. Put the `C:\fotoscan` package contents into a Git repository
2. Push the repository to GitHub
3. Confirm the repository contains:
   - `.github/workflows/ios-build.yml`
   - `source/native-ios/BarcodeCaptureApp.xcodeproj`
4. Open the GitHub repository `Actions` tab
5. Run `iOS Build Check`, or let it trigger on push/pull request

## Expected workflow steps

- Checkout repository
- Show Xcode version
- List available simulators
- Resolve Swift packages if any
- Select an available iPad simulator
- Build for iOS Simulator without code signing
- Run XCTest on selected iPad simulator
- Upload XCTest result bundle

## Expected next step

After this compile-check workflow is stable, add a second workflow for:

- code signing
- archive creation
- IPA export
- optional TestFlight upload
