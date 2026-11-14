Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$InstallDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ExePath = Join-Path $InstallDir "birdnet-go.exe"
$IconPath = Join-Path $InstallDir "icon.ico"

# Création de la fenêtre
$form = New-Object System.Windows.Forms.Form
$form.Text = "BirdNET-Go Control Panel"
$form.Size = New-Object System.Drawing.Size(400, 280)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = 'FixedSingle'
$form.MaximizeBox = $false
$form.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 30)

if (Test-Path $IconPath) { $form.Icon = New-Object System.Drawing.Icon($IconPath) }

$lblStatus = New-Object System.Windows.Forms.Label
$lblStatus.Location = New-Object System.Drawing.Point(20, 20)
$lblStatus.Size = New-Object System.Drawing.Size(340, 40)
$lblStatus.Font = New-Object System.Drawing.Font("Segoe UI", 14, [System.Drawing.FontStyle]::Bold)
$lblStatus.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
$form.Controls.Add($lblStatus)

$btnOpen = New-Object System.Windows.Forms.Button
$btnOpen.Location = New-Object System.Drawing.Point(20, 70)
$btnOpen.Size = New-Object System.Drawing.Size(340, 45)
$btnOpen.Text = "🌐 Ouvrir l'interface (localhost:8080)"
$btnOpen.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$btnOpen.BackColor = [System.Drawing.Color]::FromArgb(0, 120, 215)
$btnOpen.ForeColor = [System.Drawing.Color]::White
$btnOpen.FlatStyle = 'Flat'
$btnOpen.Add_Click({ Start-Process "http://localhost:8080" })
$form.Controls.Add($btnOpen)

$btnToggle = New-Object System.Windows.Forms.Button
$btnToggle.Location = New-Object System.Drawing.Point(20, 130)
$btnToggle.Size = New-Object System.Drawing.Size(340, 45)
$btnToggle.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$btnToggle.FlatStyle = 'Flat'
$form.Controls.Add($btnToggle)

$lblInfo = New-Object System.Windows.Forms.Label
$lblInfo.Location = New-Object System.Drawing.Point(20, 190)
$lblInfo.Size = New-Object System.Drawing.Size(340, 30)
$lblInfo.ForeColor = [System.Drawing.Color]::LightGray
$lblInfo.Text = "Le serveur tourne en arrière-plan."
$lblInfo.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
$form.Controls.Add($lblInfo)

function Update-Status {
    $isRunning = $null -ne (Get-Process -Name "birdnet-go" -ErrorAction SilentlyContinue)
    if ($isRunning) {
        $lblStatus.Text = "🟢 Statut : En cours d'exécution"
        $lblStatus.ForeColor = [System.Drawing.Color]::LightGreen
        $btnToggle.Text = "⏹️ Arrêter BirdNET-Go"
        $btnToggle.BackColor = [System.Drawing.Color]::FromArgb(200, 50, 50)
        $btnToggle.ForeColor = [System.Drawing.Color]::White
    } else {
        $lblStatus.Text = "🔴 Statut : Arrêté"
        $lblStatus.ForeColor = [System.Drawing.Color]::LightCoral
        $btnToggle.Text = "▶️ Démarrer BirdNET-Go"
        $btnToggle.BackColor = [System.Drawing.Color]::FromArgb(50, 180, 50)
        $btnToggle.ForeColor = [System.Drawing.Color]::White
    }
}

$btnToggle.Add_Click({
    $isRunning = $null -ne (Get-Process -Name "birdnet-go" -ErrorAction SilentlyContinue)
    if ($isRunning) {
        Get-Process -Name "birdnet-go" | Stop-Process -Force
        $lblInfo.Text = "Serveur arrêté."
    } else {
        Start-Process -FilePath $ExePath -ArgumentList "serve" -WorkingDirectory $InstallDir -WindowStyle Hidden
        $lblInfo.Text = "Démarrage du serveur..."
    }
    Start-Sleep -Seconds 2
    Update-Status
})

$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 2000
$timer.Add_Tick({ Update-Status })
$timer.Start()

if (-not (Get-Process -Name "birdnet-go" -ErrorAction SilentlyContinue)) {
    Start-Process -FilePath $ExePath -ArgumentList "serve" -WorkingDirectory $InstallDir -WindowStyle Hidden
    Start-Sleep -Seconds 2
}
Update-Status

[void]$form.ShowDialog()
