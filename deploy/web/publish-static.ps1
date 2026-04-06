param(
    [Parameter(Mandatory = $true)]
    [string]$Destination
)

$source = "C:\fotoscan\source\web"

if (-not (Test-Path $source)) {
    throw "Source web folder not found: $source"
}

New-Item -ItemType Directory -Force $Destination | Out-Null
Copy-Item -Path (Join-Path $source "*") -Destination $Destination -Recurse -Force

Write-Host "Published web files to $Destination"
