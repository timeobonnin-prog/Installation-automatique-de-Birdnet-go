# Test complet de l'installateur Windows : download -> SHA256 -> install -> vérif -> uninstall
$ErrorActionPreference = "Stop"
$repo = "timeobonnin-prog/Installation-automatique-de-Birdnet-go"
$assetName = "BirdNET-Go-Windows.exe"
$testDir = "C:\BirdNET-Go-Test"

Write-Host "🔎 Recherche d'une release contenant $assetName..."
$releases = gh api "repos/$repo/releases?per_page=20" | ConvertFrom-Json
$target = $null; $asset = $null
foreach ($r in $releases) {
    $a = $r.assets | Where-Object { $_.name -eq $assetName } | Select-Object -First 1
    if ($a) { $target = $r; $asset = $a; break }
}
if (-not $target) { Write-Host "::warning::Aucune release ne contient $assetName pour le moment. Test ignoré."; exit 0 }
Write-Host "✅ Release trouvée : $($target.tag_name)"

New-Item -ItemType Directory -Path "dist" -Force | Out-Null
gh release download $target.tag_name --repo $repo --pattern $assetName --dir "dist" --clobber
$installer = "dist\$assetName"

# Vérification SHA-256 (GitHub fournit digest = sha256:...)
if ($asset.digest -and $asset.digest.StartsWith("sha256:")) {
    $expected = $asset.digest.Substring(7).ToLower()
    $actual = (Get-FileHash $installer -Algorithm SHA256).Hash.ToLower()
    if ($expected -ne $actual) { Write-Error "SHA-256 invalide ! Attendu $expected, obtenu $actual"; exit 1 }
    Write-Host "🔐 SHA-256 vérifié."
}

Write-Host "📦 Installation silencieuse dans $testDir..."
$p = Start-Process -FilePath $installer -ArgumentList "/VERYSILENT","/SUPPRESSMSGBOXES","/NORESTART","/DIR=$testDir" -Wait -PassThru
if ($p.ExitCode -ne 0) { Write-Error "Échec installation (code $($p.ExitCode))"; exit 1 }

$required = @("birdnet-go.exe","BirdNET-Go-Control.exe","ffmpeg.exe","ffprobe.exe","onnxruntime.dll","tensorflowlite_c.dll","VERSION.txt","UI_VERSION.txt","icon.ico")
$missing = $required | Where-Object { -not (Test-Path "$testDir\$_") }
if ($missing) { Write-Error "Fichiers manquants après install : $($missing -join ', ')"; exit 1 }
Write-Host "✅ Tous les fichiers sont installés."

Write-Host "🧹 Désinstallation..."
$unins = "$testDir\unins000.exe"
if (Test-Path $unins) {
    Start-Process -FilePath $unins -ArgumentList "/VERYSILENT","/SUPPRESSMSGBOXES","/NORESTART" -Wait | Out-Null
    Start-Sleep -Seconds 3
}
Write-Host "🎉 Test de l'installateur réussi."
exit 0
