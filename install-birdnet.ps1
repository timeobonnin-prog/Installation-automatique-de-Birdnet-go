<#
.SYNOPSIS
    Installation automatique de BirdNET-Go pour Windows.
.DESCRIPTION
    Détecte l'architecture (x64/ARM64), récupère la dernière version
    de BirdNET-Go via l'API GitHub, télécharge le bon asset et l'installe
    dans %LOCALAPPDATA%\BirdNET-Go.
#>

$ErrorActionPreference = "Stop"

# --- 1. Détection de l'architecture ---
$osArch = [System.Runtime.InteropServices.RuntimeInformation]::OSArchitecture
$archToken = switch ($osArch) {
    "X64"   { "amd64" }
    "Arm64" { "arm64" }
    default { Write-Error "Architecture non supportée : $osArch"; exit 1 }
}
Write-Host "[OK] Architecture détectée : $osArch ($archToken)" -ForegroundColor Green

# --- 2. Récupération de la dernière version ---
$apiUrl = "https://api.github.com/repos/tphakala/birdnet-go/releases/latest"
try {
    $release = Invoke-RestMethod -Uri $apiUrl -Headers @{ "User-Agent" = "PowerShell" }
} catch {
    Write-Error "Impossible de contacter l'API GitHub : $_"; exit 1
}
$latestVersion = $release.tag_name
Write-Host "[OK] Dernière version : $latestVersion" -ForegroundColor Cyan

# --- 3. Recherche de l'asset Windows correspondant à l'architecture ---
$asset = $release.assets | Where-Object {
    $_.name -match "windows" -and $_.name -match $archToken -and $_.name -match "\.zip$"
} | Select-Object -First 1

if (-not $asset) {
    Write-Error "Aucun asset Windows/$archToken trouvé dans la release $latestVersion."
    Write-Host "Assets disponibles :" -ForegroundColor Yellow
    $release.assets | ForEach-Object { Write-Host "  - $($_.name)" }
    exit 1
}
Write-Host "[OK] Asset sélectionné : $($asset.name)" -ForegroundColor Green

# --- 4. Téléchargement ---
$installDir = Join-Path $env:LOCALAPPDATA "BirdNET-Go"
$zipPath    = Join-Path $env:TEMP $asset.name

if (-not (Test-Path $installDir)) {
    New-Item -ItemType Directory -Path $installDir -Force | Out-Null
}

Write-Host "[...] Téléchargement depuis $($asset.browser_download_url)" -ForegroundColor Yellow
try {
    Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $zipPath -UseBasicParsing
} catch {
    Write-Error "Échec du téléchargement : $_"; exit 1
}

# --- 5. Extraction ---
Write-Host "[...] Extraction vers $installDir" -ForegroundColor Yellow
try {
    Expand-Archive -Path $zipPath -DestinationPath $installDir -Force
} catch {
    Write-Error "Échec de l'extraction : $_"; exit 1
} finally {
    if (Test-Path $zipPath) { Remove-Item $zipPath -Force }
}

# --- 6. Mise à jour de VERSION.txt local si présent ---
Set-Content -Path (Join-Path $installDir "VERSION.txt") -Value $latestVersion -Encoding UTF8

Write-Host ""
Write-Host "[OK] BirdNET-Go $latestVersion installé dans $installDir" -ForegroundColor Green
Write-Host "     Exécutable : $installDir\birdnet-go.exe" -ForegroundColor Gray
Write-Host "     Config     : $installDir\config.yaml" -ForegroundColor Gray
