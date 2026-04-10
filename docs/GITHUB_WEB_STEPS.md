# GitHub Web Operation Steps

This document focuses on the exact actions to take inside the GitHub website.

## 1. Create a new GitHub repository

1. Open `https://github.com`
2. Sign in to your GitHub account
3. Click the `+` button in the top-right corner
4. Click `New repository`
5. In `Repository name`, enter your desired repository name
6. Choose `Private` or `Public`
7. Do not add:
   - README
   - .gitignore
   - license
8. Click `Create repository`

## 2. Push the local package from C:\fotoscan

Use one of these:

- `docs/FIRST_PUSH_COMMANDS.md`
- `deploy/github/first-push.ps1`

This package is prepared for this repository:

- `https://github.com/kunmark/fotoscan`

After pushing, refresh the GitHub repository page and confirm the files appear.

## 3. Check repository contents on GitHub

Open the repository home page and confirm these are visible:

- `.github/workflows/ios-build.yml`
- `.github/workflows/ios-release.yml`
- `source/native-ios/BarcodeCaptureApp.xcodeproj`
- `source/native-ios/BarcodeCaptureAppTests/BarcodeLogicTests.swift`
- `source/web/index.html`
- `docs/GITHUB_ACTIONS_IOS.md`
- `docs/GITHUB_ACTIONS_SIGNED_IOS.md`
- `docs/GITHUB_REPO_SETUP.md`

## 4. Run the unsigned iOS workflow

1. Click the `Actions` tab
2. In the left workflow list, click `iOS Build Check`
3. Click `Run workflow`
4. Select the branch, normally `main`
5. Click the green `Run workflow` button
6. Wait for the macOS runner to start
7. Open the workflow run and inspect each step:
   - Checkout repository
   - Show Xcode version
   - List available simulators
   - Resolve Swift packages if any
   - Select an available iPad simulator
   - Build for iOS Simulator without code signing
   - Run XCTest on selected iPad simulator
   - Upload XCTest result bundle

If the workflow succeeds, your project passes the first CI compile gate.
It also confirms the current native XCTest target runs on the GitHub macOS runner.

## 5. Open the GitHub secrets page

1. Go to the repository home page
2. Click `Settings`
3. In the left sidebar, click `Secrets and variables`
4. Click `Actions`
5. Click `New repository secret`

You will add four secrets here later.

## 6. Create the required secrets

Add these secret names exactly:

- `IOS_KEYCHAIN_PASSWORD`
- `IOS_P12_PASSWORD`
- `IOS_BUILD_CERTIFICATE_BASE64`
- `IOS_BUILD_PROVISION_PROFILE_BASE64`

For each secret:

1. Click `New repository secret`
2. Paste the secret name
3. Paste the secret value
4. Click `Add secret`

## 7. Edit the export options file in GitHub

If you want to edit directly in GitHub web:

1. Open `deploy/native-ios/ExportOptions.plist`
2. Click the pencil edit icon
3. Replace:
   - `REPLACE_WITH_TEAM_ID`
   - `REPLACE_WITH_PROFILE_NAME`
4. Commit the change

If you prefer local editing:

1. Edit the file in `C:\fotoscan`
2. Commit locally
3. Push to GitHub

## 8. Run the signed workflow

1. Click the `Actions` tab
2. Click `iOS Signed Archive`
3. Click `Run workflow`
4. Select branch `main`
5. Click the green `Run workflow` button
6. Open the workflow run details
7. Check these steps:
   - Decode signing certificate
   - Decode provisioning profile
   - Create temporary keychain
   - Install provisioning profile
   - Build archive
   - Export IPA
   - Upload build artifacts

## 9. Download build artifacts from GitHub

If the signed workflow succeeds:

1. Open the finished workflow run
2. Scroll to the `Artifacts` section
3. Click `ios-signed-build`
4. Download the artifact zip
5. Inspect the exported build outputs

## 10. What to do if something fails

### If `iOS Build Check` fails

Check:

- Xcode project path is still `source/native-ios/BarcodeCaptureApp.xcodeproj`
- workflow files are committed
- the native test target was not broken by later edits
- an iPad simulator was available on the runner

### If `iOS Signed Archive` fails before archive

Check:

- the four GitHub secrets exist
- base64 content was pasted correctly
- certificate password is correct
- provisioning profile matches the bundle identifier

### If archive succeeds but export fails

Check:

- `deploy/native-ios/ExportOptions.plist`
- team ID
- profile name
- export method

## 11. Recommended GitHub review path

When using GitHub as a review portal, inspect in this order:

1. `docs/DELIVERY_MANIFEST.md`
2. `docs/GITHUB_REPO_SETUP.md`
3. `docs/GITHUB_WEB_STEPS.md`
4. `docs/CODE_REVIEW_GUIDE.md`
5. `source/native-ios/BarcodeCaptureApp/ScanStore.swift`
6. `source/native-ios/BarcodeCaptureAppTests/BarcodeLogicTests.swift`
7. `source/web/app.js`
8. `.github/workflows/ios-build.yml`
9. `.github/workflows/ios-release.yml`
