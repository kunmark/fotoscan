# Deployment Guide

## 1. Web deployment

### Deployment files

Use these files from `source/web`:

- `index.html`
- `app.js`
- `styles.css`
- `manifest.json`
- `sw.js`

### Static hosting options

You can deploy the web version to any static host that serves over HTTPS, for example:

- Nginx
- Apache
- GitHub Pages
- Netlify
- Vercel static hosting
- Any object storage bucket with static website support

### Required condition

Camera mode in the browser requires HTTPS or localhost. Plain HTTP on a remote host is not acceptable if camera access is needed.

### Basic deployment method

1. Copy all files from `source/web` to the static hosting root
2. Ensure `index.html` is the default document
3. Verify the host serves:
   - `manifest.json` with JSON content type
   - `sw.js` with JavaScript content type
4. Open the app in Safari on iPad
5. Verify keyboard mode, camera mode, and CSV export

## 2. Native iOS deployment

### Deployment files

Use this project:

- `source/native-ios/BarcodeCaptureApp.xcodeproj`

### Build machine requirements

- macOS
- Xcode 15 or newer recommended
- iOS 16+ deployment target
- Apple Developer signing setup for device install or App Store/TestFlight distribution

### Basic build method

1. Open `source/native-ios/BarcodeCaptureApp.xcodeproj` in Xcode
2. Set a valid signing team
3. Replace placeholder app icons if needed
4. Build and run on a supported iPad
5. Verify:
   - keyboard scan flow
   - CSV sharing
   - camera scan flow

### Archive and export method

1. Use `deploy/native-ios/build-archive.sh` on macOS to create an archive
2. Use `deploy/native-ios/export-ipa.sh` with an export options plist to create an IPA
3. Or use `.github/workflows/ios-release.yml` after configuring signing secrets and `deploy/native-ios/ExportOptions.plist`

## 3. Review-oriented packaging

If the goal is long-term code review rather than immediate release:

1. Keep this delivery package intact
2. Review `docs/CODE_REVIEW_GUIDE.md` first
3. Review business logic files before UI polish files
4. Build web and native targets separately to isolate issues

## 4. GitHub Actions paths

Two GitHub Actions templates are included:

- `.github/workflows/ios-build.yml`
  Unsigned simulator build for compile verification
- `.github/workflows/ios-release.yml`
  Signed archive/export template using GitHub secrets

Supporting docs:

- `docs/GITHUB_ACTIONS_IOS.md`
- `docs/GITHUB_ACTIONS_SIGNED_IOS.md`
