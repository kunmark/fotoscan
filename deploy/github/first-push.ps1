param(
    [string]$RepoUrl = "https://github.com/kunmark/fotoscan.git",
    [string]$Branch = "main"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Set-Location "C:\fotoscan"

if (-not (Test-Path ".git")) {
    git init
}

git add .

try {
    git rev-parse --verify HEAD *> $null
    $hasCommit = $true
} catch {
    $hasCommit = $false
}

if (-not $hasCommit) {
    git commit -m "Initial FotoScan delivery package"
}

$remoteExists = $false
try {
    git remote get-url origin *> $null
    $remoteExists = $true
} catch {
    $remoteExists = $false
}

if (-not $remoteExists) {
    git remote add origin $RepoUrl
}

git branch -M $Branch
git push -u origin $Branch
