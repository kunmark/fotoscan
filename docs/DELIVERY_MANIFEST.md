# Delivery Manifest

## Included source code

- Web source copied from the active working prototype:
  - `source/web/index.html`
  - `source/web/app.js`
  - `source/web/styles.css`
  - `source/web/manifest.json`
  - `source/web/sw.js`
  - `source/web/README.md`
- Native iOS source copied from the generated Xcode project:
  - `source/native-ios/BarcodeCaptureApp.xcodeproj/project.pbxproj`
  - `source/native-ios/BarcodeCaptureApp/BarcodeCaptureApp.swift`
  - `source/native-ios/BarcodeCaptureApp/ContentView.swift`
  - `source/native-ios/BarcodeCaptureApp/ScanStore.swift`
  - `source/native-ios/BarcodeCaptureApp/ScannerInputField.swift`
  - `source/native-ios/BarcodeCaptureApp/CameraScannerView.swift`
  - `source/native-ios/BarcodeCaptureApp/ShareSheet.swift`
  - `source/native-ios/BarcodeCaptureApp/Assets.xcassets/...`

## Included documentation

- `docs/DEVELOPMENT_GUIDE.md`
- `docs/CODE_REVIEW_GUIDE.md`
- `docs/DEPLOYMENT_GUIDE.md`
- `docs/GITHUB_ACTIONS_IOS.md`
- `docs/GITHUB_ACTIONS_SIGNED_IOS.md`
- `docs/GITHUB_REPO_SETUP.md`
- `docs/FIRST_PUSH_COMMANDS.md`
- `docs/GITHUB_WEB_STEPS.md`
- `docs/DELIVERY_MANIFEST.md`

## Included CI workflow

- `.github/workflows/ios-build.yml`
- `.github/workflows/ios-release.yml`

## Included repository setup files

- `.gitignore`

## Included deployment files

- `deploy/web/serve-local.ps1`
- `deploy/web/publish-static.ps1`
- `deploy/github/first-push.ps1`
- `deploy/native-ios/build-archive.sh`
- `deploy/native-ios/export-ipa.sh`
- `deploy/native-ios/ExportOptions.plist`

## Scope of the package

- Review-ready source snapshot
- Web deployment instructions
- Native iOS build and archive instructions
- Helper scripts for repeatable packaging and deployment preparation

## Known limits

- iOS compilation was not executed in this Windows environment
- Native app icons are placeholders and should be replaced before production release
- Camera scanning on native iOS depends on `DataScannerViewController`, which requires a supported iPad and iOS 16+
