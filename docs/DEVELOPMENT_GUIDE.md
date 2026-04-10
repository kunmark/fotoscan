# Development Guide

## Project overview

The project has two deliverables:

- A static web prototype aimed at quick use on iPad Safari with Bluetooth scanners and browser camera scanning
- A native iPad app built with SwiftUI for a more durable production path

Both versions implement the same business workflow:

1. Capture a barcode
2. Normalize the barcode value
3. Validate structured barcode checksums where applicable
4. Classify the barcode type
5. Persist the scan locally
6. Build grouped summaries from the raw scan list
7. Export raw and summary CSV files

## Web architecture

- `index.html`
  Declares the UI structure and camera/keyboard mode controls
- `app.js`
  Holds state, scan ingestion, barcode type detection, camera access, summary building, and CSV export
- `styles.css`
  Defines the full visual system and responsive layout
- `manifest.json` and `sw.js`
  Support installable and offline-friendly browser behavior

## Native iOS architecture

- `BarcodeCaptureApp.swift`
  App entry point and environment object setup
- `ContentView.swift`
  Main screen, mode switch, summary list, log list, export actions
- `ScanStore.swift`
  Core application data model, persistence, summary generation, and CSV export
- `ScannerInputField.swift`
  UIKit bridge for focused scanner-friendly text input
- `CameraScannerView.swift`
  VisionKit bridge using `DataScannerViewController`
- `ShareSheet.swift`
  iOS share sheet wrapper for CSV export
- `BarcodeCaptureAppTests/BarcodeLogicTests.swift`
  XCTest skeleton for barcode normalization, type detection, and summary logic

## Design choices

- Local persistence is file-based for native and `localStorage`-based for web
- Structured codes such as ISBN, EAN, UPC, and ITF are checksum-validated before saving to reduce bad scans
- Summary rows are derived from raw scans instead of stored separately to prevent data divergence
- CSV export uses UTF-8 BOM so spreadsheet tools handle text reliably
- Camera scanning is integrated into the same add-scan flow instead of a separate path

## Testing expectations

For web:

- Manual keyboard entry
- Bluetooth scanner input
- Camera mode on iPad Safari where supported
- CSV generation and file download

For native iOS:

- Keyboard/scanner text entry
- Camera mode on supported iPad hardware
- CSV share sheet
- Data persistence after relaunch
