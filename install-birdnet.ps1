<#
.SYNOPSIS
    Configuration de BirdNET-Go après installation.
.PARAMETER InstallDir
    Le dossier où Inno Setup a extrait les fichiers.
#>
param (
    [string]$InstallDir = "$env:LOCALAPPDATA\BirdNET-Go"
)

$ErrorActionPreference = "Stop"

Write-Host "=== Finalisation de l'installation de BirdNET-Go ===" -ForegroundColor Cyan

# 1. Vérification du binaire
$exePath = Join-Path $InstallDir "birdnet-go.exe"
if (-not (Test-Path $exePath)) {
    Write-Error "❌ Impossible de trouver birdnet-go.exe dans $InstallDir"
    exit 1
}
Write-Host "[OK] Binaire trouvé : $exePath" -ForegroundColor Green

# 2. Affichage de la version installée (si le fichier VERSION.txt a été inclus)
$versionFile = Join-Path $InstallDir "VERSION.txt"
if (Test-Path $versionFile) {
    $version = Get-Content $versionFile -Raw
    Write-Host "[OK] Version installée : $($version.Trim())" -ForegroundColor Cyan
}

Write-Host ""
Write-Host "✅ BirdNET-Go est prêt à être utilisé !" -ForegroundColor Green
Write-Host "Pour le lancer, allez dans : $InstallDir" -ForegroundColor Gray
