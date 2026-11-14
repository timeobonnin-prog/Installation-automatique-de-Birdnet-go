# 1. Trouver le dossier de l'application de manière infaillible (corrige l'erreur Path Null)
$InstallDir = [System.AppDomain]::CurrentDomain.BaseDirectory
if ([string]::IsNullOrWhiteSpace($InstallDir)) {
    $InstallDir = Split-Path -Parent ([System.Diagnostics.Process]::GetCurrentProcess().MainModule.FileName)
}
$InstallDir = $InstallDir.TrimEnd('\')
$ExePath = Join-Path $InstallDir "birdnet-go.exe"
$IconPath = Join-Path $InstallDir "icon.ico"

# 2. Charger les bibliothèques Windows
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# 3. Création de l'interface (Fond sombre, boutons colorés)
$form = New-Object System.Windows.Forms.Form
$form.Text = "BirdNET-Go - Control Center"
$form.Size = New-Object System.Drawing.Size(420, 300)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = 'FixedSingle'
$form.MaximizeBox = $false
$form.BackColor = [System.Drawing.Color]::FromArgb(25, 25, 28)
$form.ForeColor = [System.Drawing.Color]::White

if (Test-Path $IconPath) { $form.Icon = New-Object System.Drawing.Icon($IconPath) }

# Statut (En haut)
$lblStatus = New-Object System.Windows.Forms.Label
$lblStatus.Location = New-Object System.Drawing.Point(20, 20)
$lblStatus.Size = New-Object System.Drawing.Size(360, 40)
$lblStatus.Font = New-Object System.Drawing.Font("Segoe UI", 16, [System.Drawing.FontStyle]::Bold)
$lblStatus.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
$form.Controls.Add($lblStatus)

# Bouton Ouvrir Navigateur (Bleu)
$btnOpen = New-Object System.Windows.Forms.Button
$btnOpen.Location = New-Object System.Drawing.Point(20, 70)
$btnOpen.Size = New-Object System.Drawing.Size(360, 45)
$btnOpen.Text = "🌐 Ouvrir l'interface Web (localhost:8080)"
$btnOpen.Font = New-Object System.Drawing.Font("Segoe UI", 11)
$btnOpen.BackColor = [System.Drawing.Color]::FromArgb(0, 120, 215)
$btnOpen.ForeColor = [System.Drawing.Color]::White
$btnOpen.FlatStyle = 'Flat'
$btnOpen.FlatAppearance.BorderSize = 0
$btnOpen.Cursor = [System.Windows.Forms.Cursors]::Hand
$btnOpen.Add_Click({ Start-Process "http://localhost:8080" })
$form.Controls.Add($btnOpen)

# Bouton Démarrer/Arrêter (Change de couleur)
$btnToggle = New-Object System.Windows.Forms.Button
$btnToggle.Location = New-Object System.Drawing.Point(20, 130)
$btnToggle.Size = New-Object System.Drawing.Size(360, 45)
$btnToggle.Font = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
$btnToggle.FlatStyle = 'Flat'
$btnToggle.FlatAppearance.BorderSize = 0
$btnToggle.Cursor = [System.Windows.Forms.Cursors]::Hand
$form.Controls.Add($btnToggle)

# Texte d'information (En bas)
$lblInfo = New-Object System.Windows.Forms.Label
$lblInfo.Location = New-Object System.Drawing.Point(20, 200)
$lblInfo.Size = New-Object System.Drawing.Size(360, 40)
$lblInfo.ForeColor = [System.Drawing.Color]::Gray
$lblInfo.Text = "Le serveur tourne en arrière-plan.`nFermez cette fenêtre pour la réduire dans la barre des tâches."
$lblInfo.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
$form.Controls.Add($lblInfo)

# --- FONCTIONS DE GESTION ---
function Update-Status {
    $isRunning = $null -ne (Get-Process -Name "birdnet-go" -ErrorAction SilentlyContinue)
    
    if ($isRunning) {
        $lblStatus.Text = "🟢 Serveur : EN LIGNE"
        $lblStatus.ForeColor = [System.Drawing.Color]::FromArgb(80, 250, 123)
        $btnToggle.Text = "⏹️ Arrêter le serveur"
        $btnToggle.BackColor = [System.Drawing.Color]::FromArgb(255, 85, 85)
        $btnToggle.ForeColor = [System.Drawing.Color]::White
        $btnOpen.Enabled = $true
        $trayIcon.Text = "BirdNET-Go (En ligne)"
    } else {
        $lblStatus.Text = "🔴 Serveur : HORS LIGNE"
        $lblStatus.ForeColor = [System.Drawing.Color]::FromArgb(255, 85, 85)
        $btnToggle.Text = "▶️ Démarrer le serveur"
        $btnToggle.BackColor = [System.Drawing.Color]::FromArgb(80, 250, 123)
        $btnToggle.ForeColor = [System.Drawing.Color]::Black
        $btnOpen.Enabled = $false
        $trayIcon.Text = "BirdNET-Go (Hors ligne)"
    }
}

$btnToggle.Add_Click({
    $isRunning = $null -ne (Get-Process -Name "birdnet-go" -ErrorAction SilentlyContinue)
    if ($isRunning) {
        Get-Process -Name "birdnet-go" -ErrorAction SilentlyContinue | Stop-Process -Force
    } else {
        try {
            # Démarrage invisible du serveur
            Start-Process -FilePath $ExePath -ArgumentList "serve" -WorkingDirectory $InstallDir -WindowStyle Hidden
            Start-Sleep -Seconds 2
        } catch {
            [System.Windows.Forms.MessageBox]::Show("Erreur au démarrage : `n$_", "Erreur", 0, 16)
        }
    }
    Update-Status
})

# --- SYSTEM TRAY (ICÔNE DANS LA BARRE DES TÂCHES) ---
$trayIcon = New-Object System.Windows.Forms.NotifyIcon
if (Test-Path $IconPath) { $trayIcon.Icon = New-Object System.Drawing.Icon($IconPath) }
else { $trayIcon.Icon = [System.Drawing.SystemIcons]::Application }
$trayIcon.Visible = $true

$trayMenu = New-Object System.Windows.Forms.ContextMenuStrip
$trayMenuOpen = $trayMenu.Items.Add("🌐 Ouvrir l'interface")
$trayMenuOpen.Add_Click({ Start-Process "http://localhost:8080" })

$trayMenuShow = $trayMenu.Items.Add("⚙️ Afficher le panneau de contrôle")
$trayMenuShow.Add_Click({ $form.Show(); $form.WindowState = 'Normal'; $form.Activate() })

$trayMenuExit = $trayMenu.Items.Add("❌ Quitter")
$trayMenuExit.Add_Click({
    Get-Process -Name "birdnet-go" -ErrorAction SilentlyContinue | Stop-Process -Force
    $trayIcon.Visible = $false
    [System.Windows.Forms.Application]::Exit()
})

$trayIcon.ContextMenuStrip = $trayMenu
$trayIcon.Add_DoubleClick({ $form.Show(); $form.WindowState = 'Normal'; $form.Activate() })

# --- COMPORTEMENT DE LA FENÊTRE ---
# Empêcher la fermeture du programme quand on clique sur la croix (on cache juste la fenêtre)
$form.Add_FormClosing({
    param($sender, $e)
    if ($e.CloseReason -eq 'UserClosing') {
        $e.Cancel = $true
        $form.Hide()
        $trayIcon.ShowBalloonTip(3000, "BirdNET-Go", "L'application continue de tourner dans la barre des tâches.", [System.Windows.Forms.ToolTipIcon]::Info)
    }
})

# --- TIMER (Vérifie l'état toutes les 2 secondes) ---
$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 2000
$timer.Add_Tick({ Update-Status })
$timer.Start()

# --- DÉMARRAGE INITIAL ---
# Si le serveur ne tourne pas au lancement, on le démarre
if (-not (Get-Process -Name "birdnet-go" -ErrorAction SilentlyContinue)) {
    Start-Process -FilePath $ExePath -ArgumentList "serve" -WorkingDirectory $InstallDir -WindowStyle Hidden
    Start-Sleep -Seconds 2
}
Update-Status

# Lancement de l'application
[void]$form.ShowDialog()
