# GitHub Actions Signed iOS Archive

## Included files

- `.github/workflows/ios-release.yml`
- `deploy/native-ios/ExportOptions.plist`

## Purpose

This workflow is the signed build template for archive and IPA export.

It is intended for:

- creating a signed `.xcarchive`
- exporting an `.ipa`
- uploading the build output as a GitHub Actions artifact

## Required GitHub secrets

Create these repository secrets before running the workflow:

- `IOS_KEYCHAIN_PASSWORD`
- `IOS_P12_PASSWORD`
- `IOS_BUILD_CERTIFICATE_BASE64`
- `IOS_BUILD_PROVISION_PROFILE_BASE64`

## Secret preparation

### Build certificate

Export your Apple signing certificate as `.p12`, then convert it to base64.

Example on macOS:

```bash
base64 -i build_certificate.p12 | pbcopy
```

### Provisioning profile

Download the `.mobileprovision` file, then convert it to base64.

Example on macOS:

```bash
base64 -i profile.mobileprovision | pbcopy
```

## Required file edits

Before using the signed workflow, edit:

- `deploy/native-ios/ExportOptions.plist`

Replace:

- `REPLACE_WITH_TEAM_ID`
- `REPLACE_WITH_PROFILE_NAME`

Also confirm the bundle identifier in:

- `source/native-ios/BarcodeCaptureApp.xcodeproj/project.pbxproj`

Current bundle identifier:

- `com.kunma.BarcodeCaptureApp`

## Workflow behavior

The workflow:

1. checks out the repository
2. restores the signing certificate and provisioning profile from secrets
3. creates a temporary keychain
4. imports signing credentials
5. archives the app
6. exports the IPA using `ExportOptions.plist`
7. uploads the build output as an artifact

## Important note

This workflow is a template. It is not expected to succeed until:

- signing assets match the bundle identifier
- `ExportOptions.plist` is updated
- the Apple certificate and provisioning profile are valid
