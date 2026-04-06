# Code Review Guide

## What to inspect first

- `source/web/app.js`
  Main web logic and state handling
- `source/native-ios/BarcodeCaptureApp/ScanStore.swift`
  Core business rules and persistence
- `source/native-ios/BarcodeCaptureApp/ContentView.swift`
  Main user workflow wiring
- `source/native-ios/BarcodeCaptureApp/CameraScannerView.swift`
  Native camera scanner integration

## Review checklist

- Does scan ingestion normalize barcode values consistently?
- Are duplicate scans counted correctly in summaries?
- Is exported CSV content consistent with on-screen data?
- Do camera and keyboard flows reuse the same storage logic?
- Are failure states surfaced clearly to the user?
- Does the project separate UI concerns from persistence and business logic adequately?

## Important implementation decisions

- Barcode type classification is pattern-based and intentionally lightweight
- Summary data is derived from raw scan history on demand
- Native camera scanning is implemented with `DataScannerViewController` instead of a custom AVFoundation pipeline
- Web camera scanning depends on browser support for `BarcodeDetector`

## Risks worth challenging

- Native app currently uses placeholder app icons
- Web camera support is browser-dependent and not universal
- Barcode validation is structural, not checksum-verified
- CSV export is local-first and does not include cloud synchronization

## Files that should be easy to reason about

- `source/web/index.html`
- `source/web/styles.css`
- `source/native-ios/BarcodeCaptureApp/ShareSheet.swift`
- `source/native-ios/BarcodeCaptureApp/ScannerInputField.swift`
- `source/native-ios/BarcodeCaptureAppTests/BarcodeLogicTests.swift`
