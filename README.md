# FotoScan Delivery Package

This folder is a reviewable delivery package for the barcode capture project.

## Package layout

- `source/web`
  Static web prototype for iPad Safari or any modern browser.
- `source/native-ios`
  Native iPad app source and Xcode project.
  Also includes `BarcodeCaptureAppTests` for native logic review and future CI expansion.
- `docs`
  Development notes, review guide, deployment guide, and delivery manifest.
  Includes GitHub website step-by-step operation notes.
- `.gitignore`
  Repository ignore rules for Xcode output, signing assets, and local build artifacts.
- `.github/workflows`
  GitHub Actions workflows for native iOS compile checks and signed archive/export templates.
- `deploy`
  Helper scripts for local web serving, static publishing, and native iOS build/export.

## Primary entry points

- Web app: `source/web/index.html`
- Native app: `source/native-ios/BarcodeCaptureApp.xcodeproj`

## Review goal

This package is intended to let a future reviewer inspect:

- Source code quality
- File structure and project organization
- Development assumptions
- Deployment approach for both web and native iOS deliverables
