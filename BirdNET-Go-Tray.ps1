Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# --- VARIABLES ---
$InstallDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ExePath = Join-Path $InstallDir "birdnet-go.exe"
$VersionFile = Join-Path $InstallDir "VERSION.txt"
$IconPath = Join-Path $InstallDir "icon.ico"
$ServerProcess = $null

# --- FONCTION DE MISE A JOUR ---
function Check-Updates {
    try {
        $localVersion = if (Test-Path $VersionFile) { (Get-Content $VersionFile -Raw).Trim() } else { "0.0.0" }
        $apiUrl = "https://api.github.com/repos/tphakala/birdnet-go/releases/latest"
        $release = Invoke-RestMethod -Uri $apiUrl -Headers @{ "User-Agent" = "PowerShell" }
        $latestVersion = $release.tag_name

        if ($localVersion -ne $latestVersion) {
            $trayIcon.ShowBalloonTip(3000, "Mise à jour disponible", "Téléchargement de BirdNET-Go $latestVersion...", [System.Windows.Forms.ToolTipIcon]::Info)
            
            $asset = $release.assets | Where-Object { $_.name -match "windows.*amd64.*\.tar\.gz" } | Select-Object -First 1
            $tempZip = Join-Path $env:TEMP "birdnet-update.tar.gz"
            Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $tempZip

            # Extraction du nouveau binaire
            $tempExtract = Join-Path $env:TEMP "birdnet-extract"
            New-Item -ItemType Directory -Path $tempExtract -Force | Out-Null
            tar -xzf $tempZip -C $tempExtract
            
            $newExe = Get-ChildItem -Path $tempExtract -Filter "birdnet-go.exe" -Recurse | Select-Object -First 1
            if ($newExe) {
                Stop-Server
                Copy-Item -Path $newExe.FullName -Destination $ExePath -Force
                Set-Content -Path $VersionFile -Value $latestVersion
                $trayIcon.ShowBalloonTip(3000, "Mise à jour terminée", "Redémarrage de BirdNET-Go...", [System.Windows.Forms.ToolTipIcon]::Info)
                Start-Server
            }
        } else {
            $trayIcon.ShowBalloonTip(3000, "À jour", "Vous utilisez la dernière version de BirdNET-Go.", [System.Windows.Forms.ToolTipIcon]::Info)
        }
    } catch {
        # Silencieux si pas d'internet ou erreur d'API
    }
}

# --- GESTION DU SERVEUR ---
function Start-Server {
    if (-not $ServerProcess -or $ServerProcess.HasExited) {
        $ServerProcess = Start-Process -FilePath $ExePath -ArgumentList "serve" -WorkingDirectory $InstallDir -WindowStyle Hidden -PassThru
        $menuItemStatus.Text = "Statut : En cours d'exécution"
    }
}

function Stop-Server {
    if ($ServerProcess -and -not $ServerProcess.HasExited) {
        Stop-Process -Id $ServerProcess.Id -Force
        $menuItemStatus.Text = "Statut : Arrêté"
    }
    # Tue aussi les processus fantômes
    Get-Process -Name "birdnet-go" -ErrorAction SilentlyContinue | Stop-Process -Force
}

# --- CRÉATION DE L'ICÔNE (SYSTEM TRAY) ---
$trayIcon = New-Object System.Windows.Forms.NotifyIcon
$trayIcon.Icon = New-Object System.Drawing.Icon($IconPath)
$trayIcon.Text = "BirdNET-Go"
$trayIcon.Visible = $true

# Menu contextuel (Clic droit)
$contextMenu = New-Object System.Windows.Forms.ContextMenuStrip

$menuItemStatus = New-Object System.Windows.Forms.ToolStripMenuItem
$menuItemStatus.Text = "Statut : Démarrage..."
$menuItemStatus.Enabled = $false

$menuItemOpen = New-Object System.Windows.Forms.ToolStripMenuItem
$menuItemOpen.Text = "Ouvrir l'interface web (localhost:8080)"
$menuItemOpen.Add_Click({ Start-Process "http://localhost:8080" })

$menuItemUpdate = New-Object System.Windows.Forms.ToolStripMenuItem
$menuItemUpdate.Text = "Vérifier les mises à jour"
$menuItemUpdate.Add_Click({ Check-Updates })

$menuItemExit = New-Object System.Windows.Forms.ToolStripMenuItem
$menuItemExit.Text = "Quitter BirdNET-Go"
$menuItemExit.Add_Click({
    Stop-Server
    $trayIcon.Visible = $false
    [System.Windows.Forms.Application]::Exit()
})

$contextMenu.Items.Add($menuItemStatus) | Out-Null
$contextMenu.Items.Add($menuItemOpen) | Out-Null
$contextMenu.Items.Add($menuItemUpdate) | Out-Null
$contextMenu.Items.Add((New-Object System.Windows.Forms.ToolStripSeparator)) | Out-Null
$contextMenu.Items.Add($menuItemExit) | Out-Null

$trayIcon.ContextMenuStrip = $contextMenu

# Double-clic sur l'icône = Ouvrir le site
$trayIcon.Add_DoubleClick({ Start-Process "http://localhost:8080" })

# --- DÉMARRAGE ---
Start-Server
Check-Updates

# Boucle infinie pour garder le script en vie
[System.Windows.Forms.Application]::Run()
