param(
    [int]$Port = 8080,
    [string]$Root = "C:\fotoscan\source\web"
)

if (-not (Test-Path $Root)) {
    throw "Web root not found: $Root"
}

Write-Host "Serving $Root at http://localhost:$Port"
Write-Host "For camera testing on desktop, browser security rules still apply."

Set-Location $Root
python -m http.server $Port
