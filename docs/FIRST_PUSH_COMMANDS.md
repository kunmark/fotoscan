# First GitHub Push Commands

## Option A. Direct commands

Replace the repository URL with your actual GitHub repository URL.

```powershell
Set-Location C:\fotoscan
git init
git add .
git commit -m "Initial FotoScan delivery package"
git remote add origin https://github.com/kunmark/fotoscan.git
git branch -M main
git push -u origin main
```

## Option B. Reusable PowerShell script

Use the included script:

```powershell
Set-Location C:\fotoscan
powershell -ExecutionPolicy Bypass -File .\deploy\github\first-push.ps1
```

## Recommended next commands

After the first push:

```powershell
Set-Location C:\fotoscan
git status
git remote -v
```

Then verify on GitHub:

- repository files are visible
- `Actions` tab shows `iOS Build Check`
- `.github/workflows/ios-build.yml` and `.github/workflows/ios-release.yml` are present

## If the repository already exists locally

If `C:\fotoscan` is already a git repository, use:

```powershell
Set-Location C:\fotoscan
git add .
git commit -m "Update FotoScan delivery package"
git branch -M main
git push -u origin main
```
