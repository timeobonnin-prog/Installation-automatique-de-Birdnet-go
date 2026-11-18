$ErrorActionPreference = "Stop"
$repo      = "timeobonnin-prog/Installation-automatique-de-Birdnet-go"
$assetName = "BirdNET-Go-Windows.exe"
$testDir   = "C:\BirdNET-Go-Test"

function Stop-BirdNetApps {
    foreach ($n in @("BirdNET-Go-Control", "birdnet-go")) {
        Get-Process -Name $n -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
    }
}

Write-Host "🔎 Recherche d'une release contenant $assetName..."
$releases = gh api "repos/$repo/releases?per_page=20" | ConvertFrom-Json
$target = $null; $asset = $null
foreach ($r in $releases) {
    $a = $r.assets | Where-Object { $_.name -eq $assetName } | Select-Object -First 1
    if ($a) { $target = $r; $asset = $a; break }
}
if (-not $target) { Write-Host "::warning::Aucune release ne contient $assetName. Test ignoré."; exit 0 }
Write-Host "✅ Release trouvée : $($target.tag_name)"

New-Item -ItemType Directory -Path "dist" -Force | Out-Null
gh release download $target.tag_name --repo $repo --pattern $assetName --dir "dist" --clobber
$installer = "dist\$assetName"

if ($asset.digest -and $asset.digest.StartsWith("sha256:")) {
    $expected = $asset.digest.Substring(7).ToLower()
    $actual   = (Get-FileHash $installer -Algorithm SHA256).Hash.ToLower()
    if ($expected -ne $actual) { Write-Error "SHA-256 invalide !"; exit 1 }
    Write-Host "🔐 SHA-256 vérifié."
}

Stop-BirdNetApps
Write-Host "📦 Installation silencieuse dans $testDir..."
$p = Start-Process -FilePath $installer -PassThru -ArgumentList `
    "/VERYSILENT", "/SUPPRESSMSGBOXES", "/NORESTART", "/DIR=$testDir"
if (-not $p.WaitForExit(300000)) { $p.Kill(); Write-Error "Installation trop longue (>5 min)."; exit 1 }
if ($p.ExitCode -ne 0) { Write-Error "Échec installation (code $($p.ExitCode))."; exit 1 }
Write-Host "✅ Installation terminée."

$required = @("birdnet-go.exe","BirdNET-Go-Control.exe","ffmpeg.exe","ffprobe.exe",
              "onnxruntime.dll","tensorflowlite_c.dll","VERSION.txt","UI_VERSION.txt","icon.ico")
$missing = $required | Where-Object { -not (Test-Path "$testDir\$_") }
if ($missing) { Write-Error "Fichiers manquants : $($missing -join ', ')"; exit 1 }
Write-Host "✅ Tous les fichiers sont installés."

Stop-BirdNetApps
Start-Sleep -Seconds 2

Write-Host "🧹 Désinstallation..."
$unins = "$testDir\unins000.exe"
if (Test-Path $unins) {
    $u = Start-Process -FilePath $unins -PassThru -ArgumentList "/VERYSILENT","/SUPPRESSMSGBOXES","/NORESTART"
    $u.WaitForExit(120000) | Out-Null
    for ($i = 0; $i -lt 30; $i++) {
        if (-not (Test-Path "$testDir\BirdNET-Go-Control.exe")) { break }
        Start-Sleep -Seconds 2
    }
}
Stop-BirdNetApps
Write-Host "🎉 Test de l'installateur réussi."
exit 0
