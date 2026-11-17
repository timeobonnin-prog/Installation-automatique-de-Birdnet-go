# ============================================================
#  BirdNET-Go-Tray.ps1  —  Panneau de contrôle + Tray + MAJ Auto
# ============================================================

# --- 1. VERROU SINGLE INSTANCE ---
$mutex = New-Object System.Threading.Mutex($false, "Global\BirdNET-Go-Client")
if (-not $mutex.WaitOne(0, $false)) { exit }

# --- 2. Cacher la console et activer le DPI ---
Add-Type -Name Window -Namespace Console -MemberDefinition '
[DllImport("Kernel32.dll")] public static extern IntPtr GetConsoleWindow();
[DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr hWnd, Int32 nCmdShow);
[DllImport("user32.dll")] public static extern bool SetProcessDPIAware();
'
$consolePtr = [Console.Window]::GetConsoleWindow()
[void][Console.Window]::ShowWindow($consolePtr, 0)
[void][Console.Window]::SetProcessDPIAware()

[void](Add-Type -AssemblyName PresentationFramework)
[void](Add-Type -AssemblyName PresentationCore)
[void](Add-Type -AssemblyName WindowsBase)
[void](Add-Type -AssemblyName System.Windows.Forms)
[void](Add-Type -AssemblyName System.Drawing)

# --- 3. Chemins d'installation et Logs ---
$InstallDir = [System.AppDomain]::CurrentDomain.BaseDirectory
if ([string]::IsNullOrWhiteSpace($InstallDir)) {
    $InstallDir = Split-Path -Parent ([System.Diagnostics.Process]::GetCurrentProcess().MainModule.FileName)
}
$InstallDir  = $InstallDir.TrimEnd('\')
$ExePath     = Join-Path $InstallDir "birdnet-go.exe"
$UiExePath   = Join-Path $InstallDir "BirdNET-Go-Control.exe"
$UiVersionFile = Join-Path $InstallDir "UI_VERSION.txt"
$VersionFile = Join-Path $InstallDir "VERSION.txt"
$LogDir      = Join-Path $env:LOCALAPPDATA "BirdNET-Go"
$LogFile     = Join-Path $LogDir "tray.log"

if (-not (Test-Path $LogDir)) { New-Item -ItemType Directory -Path $LogDir | Out-Null }

function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    try { Add-Content -Path $LogFile -Value "[$timestamp] $Message" -ErrorAction SilentlyContinue } catch {}
}

Write-Log "Démarrage de l'interface BirdNET-Go."

$script:crashCount = 0
$script:wasRunning = $false
$script:lastTelegramTime = [DateTime]::MinValue
$script:updateAvailable = $false

# --- 4. Interface XAML ---
$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="BirdNET-Go" Height="650" Width="850"
        WindowStartupLocation="CenterScreen" WindowStyle="None" AllowsTransparency="True" Background="Transparent"
        TextOptions.TextFormattingMode="Display" TextOptions.TextRenderingMode="ClearType"
        UseLayoutRounding="True" SnapsToDevicePixels="True">
    <Window.Resources>
        <Style TargetType="Button">
            <Setter Property="Margin" Value="0,0,0,5"/>
            <Setter Property="Height" Value="48"/>
            <Setter Property="FontSize" Value="14"/>
            <Setter Property="FontWeight" Value="SemiBold"/>
            <Setter Property="Foreground" Value="White"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border x:Name="border" CornerRadius="8" Background="{TemplateBinding Background}" BorderThickness="1" BorderBrush="#334155">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="border" Property="Opacity" Value="0.85"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
        <Style x:Key="WindowBtn" TargetType="Button">
            <Setter Property="Width" Value="45"/>
            <Setter Property="Height" Value="35"/>
            <Setter Property="Background" Value="Transparent"/>
            <Setter Property="Foreground" Value="#94A3B8"/>
            <Setter Property="FontSize" Value="14"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border x:Name="border" Background="{TemplateBinding Background}">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="border" Property="Background" Value="#1E293B"/>
                                <Setter Property="Foreground" Value="White"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
    </Window.Resources>
    <Border CornerRadius="12" Background="#0F172A" BorderBrush="#1E293B" BorderThickness="1" Margin="10">
        <Border.Effect><DropShadowEffect Color="Black" BlurRadius="20" ShadowDepth="0" Opacity="0.5"/></Border.Effect>
        <Grid>
            <Grid.RowDefinitions>
                <RowDefinition Height="40"/>
                <RowDefinition Height="*"/>
            </Grid.RowDefinitions>
            <Grid Grid.Row="0" Background="Transparent" Name="TitleBar">
                <TextBlock Text="BirdNET-Go // Control Center" Foreground="#64748B" FontSize="12" VerticalAlignment="Center" Margin="20,0,0,0"/>
                <StackPanel Orientation="Horizontal" HorizontalAlignment="Right">
                    <Button Style="{StaticResource WindowBtn}" Content="—" Name="BtnMinimize"/>
                    <Button Style="{StaticResource WindowBtn}" Content="✕" Name="BtnClose"/>
                </StackPanel>
            </Grid>
            <Grid Grid.Row="1">
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="240"/>
                    <ColumnDefinition Width="*"/>
                </Grid.ColumnDefinitions>
                <Border Grid.Column="0" Background="#020617" CornerRadius="0,0,0,12">
                    <StackPanel Margin="20,30,20,0">
                        <TextBlock Text="BirdNET-Go" Foreground="#38BDF8" FontSize="22" FontWeight="Bold" Margin="0,0,0,40"/>
                        <TextBlock Text="MENU" Foreground="#475569" FontSize="10" FontWeight="Bold" Margin="10,0,0,10"/>
                        <Border Background="#1E293B" CornerRadius="8" Padding="15,10" Margin="0,0,0,5">
                            <TextBlock Text="Dashboard" Foreground="White" FontSize="14" FontWeight="Bold"/>
                        </Border>
                        <TextBlock Text="LIENS" Foreground="#475569" FontSize="10" FontWeight="Bold" Margin="10,20,0,10"/>
                        <Border Background="Transparent" CornerRadius="8" Padding="15,10" Margin="0,0,0,5" Cursor="Hand" Name="LinkGitHub">
                            <StackPanel Orientation="Horizontal">
                                <Viewbox Width="16" Height="16" Margin="0,0,10,0">
                                    <Path Fill="#94A3B8" Data="M12 0c-6.626 0-12 5.373-12 12 0 5.302 3.438 9.8 8.207 11.387.599.111.793-.261.793-.577v-2.234c-3.338.726-4.033-1.416-4.033-1.416-.546-1.387-1.333-1.756-1.333-1.756-1.089-.745.083-.729.083-.729 1.205.084 1.839 1.237 1.839 1.237 1.07 1.834 2.807 1.304 3.492.997.107-.775.418-1.305.762-1.604-2.665-.305-5.467-1.334-5.467-5.931 0-1.311.469-2.381 1.236-3.221-.124-.303-.535-1.524.117-3.176 0 0 1.008-.322 3.301 1.23.957-.266 1.983-.399 3.003-.404 1.02.005 2.047.138 3.006.404 2.291-1.552 3.297-1.23 3.297-1.23.653 1.653.242 2.874.118 3.176.77.84 1.235 1.911 1.235 3.221 0 4.609-2.807 5.624-5.479 5.921.43.372.823 1.102.823 2.222v3.293c0 .319.192.694.801.576 4.765-1.589 8.199-6.086 8.199-11.386 0-6.627-5.373-12-12-12z"/>
                                </Viewbox>
                                <TextBlock Text="Dépôt GitHub" Foreground="#94A3B8" FontSize="14" VerticalAlignment="Center"/>
                            </StackPanel>
                        </Border>
                        <Border Background="Transparent" CornerRadius="8" Padding="15,10" Cursor="Hand" Name="LinkReleases">
                            <StackPanel Orientation="Horizontal">
                                <Viewbox Width="16" Height="16" Margin="0,0,10,0">
                                    <Path Fill="#94A3B8" Data="M19 9h-4V3H9v6H5l7 7 7-7zM5 18v2h14v-2H5z"/>
                                </Viewbox>
                                <TextBlock Text="Dernières Versions" Foreground="#94A3B8" FontSize="14" VerticalAlignment="Center"/>
                            </StackPanel>
                        </Border>
                    </StackPanel>
                </Border>
                <Grid Grid.Column="1" Margin="40">
                    <Grid.RowDefinitions>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="*"/>
                    </Grid.RowDefinitions>
                    <TextBlock Grid.Row="0" Text="Dashboard" Foreground="#F8FAFC" FontSize="32" FontWeight="Bold"/>
                    <StackPanel Grid.Row="1" Margin="0,30,0,0">
                        <Border Background="#1E293B" CornerRadius="8" Padding="25" Margin="0,0,0,20" BorderThickness="1" BorderBrush="#334155">
                            <Grid>
                                <Grid.ColumnDefinitions>
                                    <ColumnDefinition Width="Auto"/>
                                    <ColumnDefinition Width="*"/>
                                </Grid.ColumnDefinitions>
                                <Ellipse Grid.Column="0" Width="12" Height="12" Fill="#EF4444" Name="StatusDot" VerticalAlignment="Center" Margin="0,0,15,0"/>
                                <StackPanel Grid.Column="1">
                                    <TextBlock Text="ÉTAT DU SYSTÈME" Foreground="#94A3B8" FontSize="11" FontWeight="Bold" Margin="0,0,0,5"/>
                                    <TextBlock Text="HORS LIGNE" Foreground="#EF4444" FontSize="20" FontWeight="Bold" Name="TxtStatus"/>
                                </StackPanel>
                            </Grid>
                        </Border>
                        <Button Name="BtnOpen"   Content="OUVRIR L'INTERFACE WEB" Background="#0284C7" Margin="0,0,0,12"/>
                        <Button Name="BtnToggle" Content="DÉMARRER LE SERVEUR"     Background="#10B981" Margin="0,0,0,20"/>
                        
                        <Button Name="BtnUpdate" Content="METTRE À JOUR BIRDNET-GO" Background="#8B5CF6"/>
                        <TextBlock Name="TxtUpdateStatus" Text="Vérification en cours..." Foreground="#64748B" FontSize="11" HorizontalAlignment="Center" Margin="0,0,0,0"/>
                    </StackPanel>
                </Grid>
            </Grid>
        </Grid>
    </Border>
</Window>
"@

$reader = New-Object System.Xml.XmlNodeReader ([xml]$xaml)
$window = [Windows.Markup.XamlReader]::Load($reader)

$TitleBar      = $window.FindName("TitleBar")
$StatusDot     = $window.FindName("StatusDot")
$TxtStatus     = $window.FindName("TxtStatus")
$BtnToggle     = $window.FindName("BtnToggle")
$BtnOpen       = $window.FindName("BtnOpen")
$BtnUpdate     = $window.FindName("BtnUpdate")
$TxtUpdateStatus = $window.FindName("TxtUpdateStatus")
$BtnClose      = $window.FindName("BtnClose")
$BtnMinimize   = $window.FindName("BtnMinimize")
$LinkGitHub    = $window.FindName("LinkGitHub")
$LinkReleases  = $window.FindName("LinkReleases")

[void]$TitleBar.Add_MouseLeftButtonDown({ $window.DragMove() })
[void]$BtnMinimize.Add_Click({ $window.WindowState = 'Minimized' })

# --- 5. FERMETURE (Cacher sans arrêter le serveur) ---
[void]$BtnClose.Add_Click({
    $window.Hide()
    [void]$trayIcon.ShowBalloonTip(3000, "BirdNET-Go", "L'application continue de tourner en arrière-plan.", [System.Windows.Forms.ToolTipIcon]::Info)
})

# --- 6. LIENS ---
[void]$LinkGitHub.Add_MouseLeftButtonUp({ Start-Process "https://github.com/timeobonnin-prog/Installation-automatique-de-Birdnet-go" })
[void]$LinkReleases.Add_MouseLeftButtonUp({ Start-Process "https://github.com/timeobonnin-prog/Installation-automatique-de-Birdnet-go/releases/latest" })
[void]$BtnOpen.Add_Click({ Start-Process "http://localhost:8080" })

# --- 7. NOTIFICATION TELEGRAM (Anti-Spam) ---
function Send-TelegramNotification {
    param([string]$Message)
    if ((Get-Date).Subtract($script:lastTelegramTime).TotalMinutes -lt 5) { return }

    $botToken = "TON_BOT_TOKEN" # À REMPLACER
    $chatId = "TON_CHAT_ID"   # À REMPLACER
    
    try {
        $url = "https://api.telegram.org/bot$botToken/sendMessage"
        $body = @{ chat_id = $chatId; text = $Message; parse_mode = "Markdown" } | ConvertTo-Json
        Invoke-RestMethod -Uri $url -Method Post -Body $body -ContentType "application/json" -TimeoutSec 5 | Out-Null
        $script:lastTelegramTime = Get-Date
    } catch {}
}

# --- 8. MISE À JOUR GLOBALE ---
function Update-All {
    $ProgressPreference = 'SilentlyContinue'
    try {
        $release = Invoke-RestMethod -Uri "https://api.github.com/repos/timeobonnin-prog/Installation-automatique-de-Birdnet-go/releases/latest" -Headers @{ "User-Agent" = "PowerShell" } -TimeoutSec 5
        $asset = $release.assets | Where-Object { $_.name -eq "BirdNET-Go-Windows.exe" } | Select-Object -First 1
        if (-not $asset) { throw "Installateur introuvable" }

        $tempInstaller = Join-Path $env:TEMP "BirdNET-Go-Update.exe"
        Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $tempInstaller -TimeoutSec 300

        $msg = "Une nouvelle version est disponible. L'application va se fermer (y compris l'icône dans la barre des tâches) pour lancer l'installateur. Voulez-vous continuer ?"
        $result = [System.Windows.MessageBox]::Show($msg, "Mise à jour disponible", "YesNo", "Question")
        
        if ($result -eq "No") { return }

        $BtnUpdate.Content = "MISE À JOUR..."
        $BtnUpdate.IsEnabled = $false
        $BtnUpdate.Background = "#10B981"
        
        Get-Process -Name "birdnet-go" -ErrorAction SilentlyContinue | Stop-Process -Force
        $trayIcon.Visible = $false
        
        Start-Process -FilePath $tempInstaller -ArgumentList "/VERYSILENT", "/SUPPRESSMSGBOXES", "/NORESTART"
        
        [System.Windows.Application]::Current.Shutdown()
    }
    catch {
        $BtnUpdate.Content = "ERREUR MISE À JOUR"
        $BtnUpdate.Background = "#EF4444"
        Start-Sleep -Seconds 3
        $BtnUpdate.Content = "METTRE À JOUR BIRDNET-GO"
        $BtnUpdate.Background = "#8B5CF6"
        $BtnUpdate.IsEnabled = $true
    }
}
[void]$BtnUpdate.Add_Click({ Update-All })

# --- 9. LOGIQUE DÉMARRAGE / ARRÊT & CRASHS ---
function Update-UI {
    $isRunning = $null -ne (Get-Process -Name "birdnet-go" -ErrorAction SilentlyContinue)
    
    # Détection du crash
    if ($script:wasRunning -and -not $isRunning) {
        $script:crashCount++
        Write-Log "⚠️ Le serveur a planté ! (Fois : $script:crashCount)"
        
        if ($script:crashCount -le 3) {
            Start-Process -FilePath $ExePath -ArgumentList "serve" -WorkingDirectory $InstallDir -WindowStyle Hidden
            Send-TelegramNotification "⚠️ *BirdNET-Go a planté !*`nRedémarrage automatique ($($script:crashCount)/3)."
        } else {
            Send-TelegramNotification "❌ *BirdNET-Go a planté 3 fois.*`nArrêt des redémarrages."
        }
    }
    if ($isRunning) { $script:crashCount = 0 }
    $script:wasRunning = $isRunning

    if ($isRunning) {
        $TxtStatus.Text       = "EN LIGNE"
        $TxtStatus.Foreground = "#10B981"
        $StatusDot.Fill       = "#10B981"
        $BtnToggle.Content    = "ARRÊTER LE SERVEUR"
        $BtnToggle.Background = "#E11D48"
        $BtnOpen.IsEnabled    = $true
        $BtnOpen.Opacity      = 1
        
        # 🔥 L'icône apparaît SEULEMENT si le serveur tourne
        $trayIcon.Visible = $true
        $trayIcon.Text = "BirdNET-Go - En ligne"
    }
    else {
        $TxtStatus.Text       = "HORS LIGNE"
        $TxtStatus.Foreground = "#EF4444"
        $StatusDot.Fill       = "#EF4444"
        $BtnToggle.Content    = "DÉMARRER LE SERVEUR"
        $BtnToggle.Background = "#10B981"
        $BtnOpen.IsEnabled    = $false
        $BtnOpen.Opacity      = 0.5
        
        # 🔥 L'icône DISPARAÎT si le serveur est arrêté
        $trayIcon.Visible = $false
        $trayIcon.Text = "BirdNET-Go - Hors ligne"
    }
}

[void]$BtnToggle.Add_Click({
    if ($null -ne (Get-Process -Name "birdnet-go" -ErrorAction SilentlyContinue)) {
        Get-Process -Name "birdnet-go" -ErrorAction SilentlyContinue | Stop-Process -Force
        Write-Log "Serveur arrêté manuellement."
    } else {
        if (Test-Path $ExePath) {
            Start-Process -FilePath $ExePath -ArgumentList "serve" -WorkingDirectory $InstallDir -WindowStyle Hidden
            Write-Log "Serveur démarré manuellement."
            Start-Sleep -Seconds 2
        }
    }
    Update-UI
})

# --- 10. SYSTEM TRAY (Badge visuel) ---
$trayIcon = New-Object System.Windows.Forms.NotifyIcon
$IconPath = Join-Path $InstallDir "icon.ico"
if (Test-Path $IconPath) { $trayIcon.Icon = New-Object System.Drawing.Icon($IconPath) } else { $trayIcon.Icon = [System.Drawing.SystemIcons]::Application }
$trayIcon.Text = "BirdNET-Go Control Center"
# On ne rend pas l'icône visible ici, c'est Update-UI qui s'en charge
$trayIcon.Visible = $false

$trayMenu = New-Object System.Windows.Forms.ContextMenuStrip
[void]$trayMenu.Items.Add("🌐 Ouvrir l'interface web").Add_Click({ Start-Process "http://localhost:8080" })
[void]$trayMenu.Items.Add("⚙️ Afficher le panneau").Add_Click({ $window.Show(); $window.WindowState = 'Normal'; $window.Activate() })
[void]$trayMenu.Items.Add("❌ Quitter complètement").Add_Click({
    Get-Process -Name "birdnet-go" -ErrorAction SilentlyContinue | Stop-Process -Force
    $trayIcon.Visible = $false
    Write-Log "Application quittée par l'utilisateur."
    try { $mutex.ReleaseMutex() } catch { }
    [System.Windows.Forms.Application]::Exit()
})
$trayIcon.ContextMenuStrip = $trayMenu
[void]$trayIcon.Add_DoubleClick({ $window.Show(); $window.WindowState = 'Normal'; $window.Activate() })

[void]$window.Add_Closing({
    param($sender, $e)
    if ($e.CloseReason -eq 'UserClosing') {
        $e.Cancel = $true
        $window.Hide()
        [void]$trayIcon.ShowBalloonTip(3000, "BirdNET-Go", "L'application est réduite dans la barre des tâches.", [System.Windows.Forms.ToolTipIcon]::Info)
    }
})

# --- 11. TIMER DU STATUT ---
$timer = New-Object System.Windows.Threading.DispatcherTimer
$timer.Interval = [TimeSpan]::FromMilliseconds(500)
[void]$timer.Add_Tick({ Update-UI })
$timer.Start()

# --- 12. VÉRIFICATION ASYNCHRONE ---
$script:lastUpdateCheck = [DateTime]::MinValue

function Check-ForUpdatesAsync {
    $job = Start-ThreadJob -ScriptBlock {
        try {
            $release = Invoke-RestMethod -Uri "https://api.github.com/repos/timeobonnin-prog/Installation-automatique-de-Birdnet-go/releases/latest" -Headers @{ "User-Agent" = "PowerShell" } -TimeoutSec 3
            return $release.tag_name
        } catch {
            return $null
        }
    }
    
    $checkTimer = New-Object System.Windows.Threading.DispatcherTimer
    $checkTimer.Interval = [TimeSpan]::FromMilliseconds(500)
    $checkTimer.Add_Tick({
        if ($job.State -eq 'Completed') {
            $checkTimer.Stop()
            $latestTag = $job | Receive-Job
            $job | Remove-Job -Force
            
            if ($latestTag) {
                $localUiVersion = if (Test-Path $UiVersionFile) { [System.IO.File]::ReadAllText($UiVersionFile).Trim() } else { "0.0.0" }
                
                if ($localUiVersion -ne $latestTag) {
                    $BtnUpdate.Content = "⚡ NOUVELLE VERSION DISPO !"
                    $BtnUpdate.Background = "#10B981"
                    $TxtUpdateStatus.Text = "Mise à jour disponible : $latestTag"
                    $TxtUpdateStatus.Foreground = "#F59E0B"
                } else {
                    $BtnUpdate.Content = "METTRE À JOUR BIRDNET-GO"
                    $BtnUpdate.Background = "#8B5CF6"
                    $TxtUpdateStatus.Text = "Application à jour ($localUiVersion)"
                    $TxtUpdateStatus.Foreground = "#10B981"
                }
            } else {
                $TxtUpdateStatus.Text = "Vérification impossible (hors ligne)"
                $TxtUpdateStatus.Foreground = "#EF4444"
            }
        }
    })
    $checkTimer.Start()
}

$startupTimer = New-Object System.Windows.Threading.DispatcherTimer
$startupTimer.Interval = [TimeSpan]::FromSeconds(2)
$startupTimer.Add_Tick({
    $startupTimer.Stop()
    Check-ForUpdatesAsync
})
$startupTimer.Start()

$dailyTimer = New-Object System.Windows.Threading.DispatcherTimer
$dailyTimer.Interval = [TimeSpan]::FromMinutes(1)
$dailyTimer.Add_Tick({
    $now = Get-Date
    if ($now.Hour -eq 15 -and $now.Minute -eq 0 -and (($now - $script:lastUpdateCheck).TotalHours -gt 23)) {
        Check-ForUpdatesAsync
        $script:lastUpdateCheck = Get-Date
    }
})
$dailyTimer.Start()

# --- 13. DÉMARRAGE INITIAL ---
if ($null -eq (Get-Process -Name "birdnet-go" -ErrorAction SilentlyContinue)) {
    if (Test-Path $ExePath) {
        Start-Process -FilePath $ExePath -ArgumentList "serve" -WorkingDirectory $InstallDir -WindowStyle Hidden
        Start-Sleep -Seconds 2
    }
}
Update-UI

[void]$window.ShowDialog()
