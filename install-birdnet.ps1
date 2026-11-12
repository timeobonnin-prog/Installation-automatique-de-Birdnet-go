<#
.SYNOPSIS
    Installation automatique de BirdNET-Go pour Windows.
#>

$ErrorActionPreference = "Stop"

Write-Host "=== Installation de BirdNET-Go ===" -ForegroundColor Cyan

# 1. Détection de l'architecture
$osArch = [System.Runtime.InteropServices.RuntimeInformation]::OSArchitecture
$archToken = switch ($osArch) {
    "X64"   { "amd64" }
    "Arm64" { "arm64" }
    default { Write-Error "Architecture non supportée : $osArch"; exit 1 }
}
Write-Host "[OK] Architecture : $osArch ($archToken)" -ForegroundColor Green

# 2. Dernière version
$apiUrl = "https://api.github.com/repos/tphakala/birdnet-go/releases/latest"
try {
    $release = Invoke-RestMethod -Uri $apiUrl -Headers @{ "User-Agent" = "PowerShell" }
} catch {
    Write-Error "Impossible de contacter l'API GitHub : $_"; exit 1
}
$latestVersion = $release.tag_name
Write-Host "[OK] Version : $latestVersion" -ForegroundColor Cyan

# 3. Asset Windows correspondant (recherche de .tar.gz)
$asset = $release.assets | Where-Object {
    $_.name -match "windows" -and $_.name -match $archToken -and $_.name -match "\.tar\.gz$"
} | Select-Object -First 1

if (-not $asset) {
    Write-Error "Aucun asset Windows/$archToken (.tar.gz) trouvé dans $latestVersion."
    $release.assets | ForEach-Object { Write-Host "  - $($_.name)" }
    exit 1
}
Write-Host "[OK] Asset : $($asset.name)" -ForegroundColor Green

# 4. Téléchargement
$installDir = Join-Path $env:LOCALAPPDATA "BirdNET-Go"
$archivePath = Join-Path $env:TEMP $asset.name

if (-not (Test-Path $installDir)) {
    New-Item -ItemType Directory -Path $installDir -Force | Out-Null
}

Write-Host "[...] Téléchargement..." -ForegroundColor Yellow
try {
    Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $archivePath -UseBasicParsing
} catch {
    Write-Error "Échec du téléchargement : $_"; exit 1
}

# 5. Extraction (utilise tar pour les .tar.gz)
Write-Host "[...] Extraction vers $installDir" -ForegroundColor Yellow
try {
    tar -xzf $archivePath -C $installDir
} catch {
    Write-Error "Échec de l'extraction : $_"; exit 1
} finally {
    if (Test-Path $archivePath) { Remove-Item $archivePath -Force }
}

Set-Content -Path (Join-Path $installDir "VERSION.txt") -Value $latestVersion -Encoding UTF8

Write-Host ""
Write-Host "[OK] BirdNET-Go $latestVersion installé dans $installDir" -ForegroundColor Green
