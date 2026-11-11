<#
.SYNOPSIS
    Installation automatique de BirdNET-Go pour Windows.
.DESCRIPTION
    Détecte l'architecture (x64/ARM64), télécharge la dernière version
    de BirdNET-Go depuis GitHub et l'installe dans %LOCALAPPDATA%.
#>

$ErrorActionPreference = "Stop"

# 1. Détection de l'architecture
$osArch = [System.Runtime.InteropServices.RuntimeInformation]::OSArchitecture
$assetSuffix = ""

switch ($osArch) {
    "X64"    { $assetSuffix = "windows_amd64"; Write-Host "[OK] Architecture x64 détectée." -ForegroundColor Green }
    "Arm64"  { $assetSuffix = "windows_arm64"; Write-Host "[OK] Architecture ARM64 détectée." -ForegroundColor Green }
    default  { Write-Error "Architecture non supportée : $osArch"; exit 1 }
}

# 2. Récupération de la dernière version via l'API GitHub
$apiUrl = "https://api.github.com/repos/tphakala/birdnet-go/releases/latest"
try {
    $release = Invoke-RestMethod -Uri $apiUrl -Headers @{ "User-Agent" = "PowerShell" }
    $latestVersion = $release.tag_name
    Write-Host "[OK] Dernière version disponible : $latestVersion" -ForegroundColor Cyan
} catch {
    Write-Error "Impossible de récupérer la dernière version : $_"
    exit 1
}

# 3. Construction du nom de l'archive
# Les assets suivent le modèle : gobirdnet_vX.Y.Z_windows_amd64.zip
$zipName = "gobirdnet_${latestVersion}_${assetSuffix}.zip"
$downloadUrl = "https://github.com/tphakala/birdnet-go/releases/download/${latestVersion}/${zipName}"

# 4. Téléchargement et extraction
$installDir = Join-Path $env:LOCALAPPDATA "BirdNET-Go"
$zipPath = Join-Path $env:TEMP $zipName

if (-not (Test-Path $installDir)) {
    New-Item -ItemType Directory -Path $installDir -Force | Out-Null
    Write-Host "[OK] Dossier d'installation créé : $installDir" -ForegroundColor Green
}

Write-Host "[...] Téléchargement de $zipName ..." -ForegroundColor Yellow
try {
    Invoke-WebRequest -Uri $downloadUrl -OutFile $zipPath -UseBasicParsing
} catch {
    Write-Error "Échec du téléchargement depuis $downloadUrl : $_"
    exit 1
}

Write-Host "[...] Extraction vers $installDir ..." -ForegroundColor Yellow
try {
    Expand-Archive -Path $zipPath -DestinationPath $installDir -Force
} catch {
    Write-Error "Échec de l'extraction : $_"
    exit 1
} finally {
    if (Test-Path $zipPath) { Remove-Item $zipPath -Force }
}

Write-Host "[OK] BirdNET-Go $latestVersion installé dans $installDir" -ForegroundColor Green
Write-Host "   Exécutable : $installDir\birdnet-go.exe" -ForegroundColor Gray
Write-Host "   Configuration : $installDir\config.yaml" -ForegroundColor Gray
