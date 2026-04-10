# GitHub Repository Setup Checklist

## Goal

This checklist turns the delivery package in `C:\fotoscan` into a GitHub repository that supports:

- source review
- unsigned iOS compile checks
- signed iOS archive/export after secrets are configured

## Recommended repository structure

Keep the package layout unchanged:

- `.github/workflows`
- `source/web`
- `source/native-ios`
- `docs`
- `deploy`

## Step 1. Initialize a local git repository

In PowerShell:

```powershell
Set-Location C:\fotoscan
git init
git add .
git commit -m "Initial FotoScan delivery package"
```

## Step 2. Create a GitHub repository

Create a new GitHub repository, then connect the local folder:

```powershell
Set-Location C:\fotoscan
git remote add origin <YOUR_GITHUB_REPOSITORY_URL>
git branch -M main
git push -u origin main
```

There is also a reusable script in:

- `deploy/github/first-push.ps1`

Current repository URL for this project:

- `https://github.com/kunmark/fotoscan.git`

Direct command version for this repository:

```powershell
Set-Location C:\fotoscan
git remote add origin https://github.com/kunmark/fotoscan.git
git branch -M main
git push -u origin main
```

## Step 3. Verify the initial repository contents

Confirm these files exist in GitHub:

- `.github/workflows/ios-build.yml`
- `.github/workflows/ios-release.yml`
- `source/native-ios/BarcodeCaptureApp.xcodeproj`
- `source/web/index.html`
- `docs/GITHUB_ACTIONS_IOS.md`
- `docs/GITHUB_ACTIONS_SIGNED_IOS.md`

## Step 4. Run the unsigned iOS compile workflow

Open the GitHub repository and go to:

- `Actions`
- `iOS Build Check`

Run it manually or trigger it with a push to `main`.

Expected result:

- GitHub macOS runner can read the Xcode project
- the native app compiles for simulator without code signing
- the native XCTest target runs on an iPad simulator

## Step 5. Prepare signing assets for the release workflow

You need:

- Apple signing certificate exported as `.p12`
- provisioning profile `.mobileprovision`
- a password for the temporary CI keychain
- the `.p12` export password

## Step 6. Convert signing assets to base64

On macOS:

```bash
base64 -i build_certificate.p12 | pbcopy
base64 -i profile.mobileprovision | pbcopy
```

On Windows PowerShell:

```powershell
[Convert]::ToBase64String([IO.File]::ReadAllBytes("C:\path\build_certificate.p12")) | Set-Clipboard
[Convert]::ToBase64String([IO.File]::ReadAllBytes("C:\path\profile.mobileprovision")) | Set-Clipboard
```

## Step 7. Create GitHub repository secrets

Add these secrets in GitHub:

- `IOS_KEYCHAIN_PASSWORD`
- `IOS_P12_PASSWORD`
- `IOS_BUILD_CERTIFICATE_BASE64`
- `IOS_BUILD_PROVISION_PROFILE_BASE64`

GitHub path:

- `Settings`
- `Secrets and variables`
- `Actions`

## Step 8. Update export configuration

Edit:

- `deploy/native-ios/ExportOptions.plist`

Replace:

- `REPLACE_WITH_TEAM_ID`
- `REPLACE_WITH_PROFILE_NAME`

Also verify:

- bundle identifier in `source/native-ios/BarcodeCaptureApp.xcodeproj/project.pbxproj`

Current value:

- `com.kunma.BarcodeCaptureApp`

## Step 9. Run the signed workflow

After the secrets and export options are ready:

- open GitHub `Actions`
- run `iOS Signed Archive`

Expected result:

- `.xcarchive` is created
- `.ipa` export is attempted
- build artifacts are uploaded to the workflow run

## Step 10. Review checklist for future audits

When reviewing this repository later, inspect in this order:

1. `docs/DELIVERY_MANIFEST.md`
2. `docs/DEVELOPMENT_GUIDE.md`
3. `docs/CODE_REVIEW_GUIDE.md`
4. `source/native-ios/BarcodeCaptureApp/ScanStore.swift`
5. `source/native-ios/BarcodeCaptureApp/ContentView.swift`
6. `source/web/app.js`
7. `.github/workflows/ios-build.yml`
8. `.github/workflows/ios-release.yml`

## Optional next improvements

- add unit tests for barcode normalization and summary generation
- add a release branch strategy
- add automatic version tagging
- add TestFlight upload in the release workflow
