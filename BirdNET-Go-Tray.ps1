# ============================================================
#  BirdNET-Go-Tray.ps1  —  Panneau de contrôle + Tray + MAJ
# ============================================================

# --- 1. VERROU SINGLE INSTANCE ---
$mutex = New-Object System.Threading.Mutex($false, "Global\BirdNET-Go-Client")
if (-not $mutex.WaitOne(0, $false)) {
    exit
}

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

# --- 3. Chemins d'installation ---
$InstallDir = [System.AppDomain]::CurrentDomain.BaseDirectory
if ([string]::IsNullOrWhiteSpace($InstallDir)) {
    $InstallDir = Split-Path -Parent ([System.Diagnostics.Process]::GetCurrentProcess().MainModule.FileName)
}
$InstallDir  = $InstallDir.TrimEnd('\')
$ExePath     = Join-Path $InstallDir "birdnet-go.exe"
$VersionFile = Join-Path $InstallDir "VERSION.txt"

# --- 4. Interface XAML (Boutons explicites) ---
$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="BirdNET-Go" Height="650" Width="850"
        WindowStartupLocation="CenterScreen" WindowStyle="None" AllowsTransparency="True" Background="Transparent"
        TextOptions.TextFormattingMode="Display"
        TextOptions.TextRenderingMode="ClearType"
        UseLayoutRounding="True" SnapsToDevicePixels="True">

    <Window.Resources>
        <Style TargetType="Button">
            <Setter Property="Margin" Value="0,0,0,12"/>
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
        <Border.Effect>
            <DropShadowEffect Color="Black" BlurRadius="20" ShadowDepth="0" Opacity="0.5"/>
        </Border.Effect>
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

                        <Button Name="BtnOpen"   Content="OUVRIR L'INTERFACE WEB" Background="#0284C7"/>
                        <Button Name="BtnToggle" Content="DÉMARRER LE SERVEUR"     Background="#10B981"/>
                        
                        <!-- Les deux boutons de mise à jour distincts -->
                        <Button Name="BtnUpdateServer" Content="METTRE À JOUR LE MOTEUR (BIRDNET-GO)" Background="#8B5CF6"/>
                        <Button Name="BtnUpdateUI"     Content="METTRE À JOUR L'INTERFACE (CONTRÔLEUR)" Background="#F59E0B"/>
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
$BtnUpdateServer = $window.FindName("BtnUpdateServer")
$BtnUpdateUI     = $window.FindName("BtnUpdateUI")
$BtnClose      = $window.FindName("BtnClose")
$BtnMinimize   = $window.FindName("BtnMinimize")
$LinkGitHub    = $window.FindName("LinkGitHub")
$LinkReleases  = $window.FindName("LinkReleases")

[void]$TitleBar.Add_MouseLeftButtonDown({ $window.DragMove() })
[void]$BtnMinimize.Add_Click({ $window.WindowState = 'Minimized' })

# --- 5. FERMETURE ---
[void]$BtnClose.Add_Click({
    $window.Hide()
    [void]$trayIcon.ShowBalloonTip(3000, "BirdNET-Go", "L'application continue de tourner en arrière-plan.", [System.Windows.Forms.ToolTipIcon]::Info)
})

# --- 6. LIENS ---
[void]$LinkGitHub.Add_MouseLeftButtonUp({ Start-Process "https://github.com/timeobonnin-prog/Installation-automatique-de-Birdnet-go" })
[void]$LinkReleases.Add_MouseLeftButtonUp({ Start-Process "https://github.com/timeobonnin-prog/Installation-automatique-de-Birdnet-go/releases/latest" })
[void]$BtnOpen.Add_Click({ Start-Process "http://localhost:8080" })

# --- 7. LOGIQUE : MISE À JOUR DU MOTEUR (Backend) ---
function Update-BirdNETGo {
    $BtnUpdateServer.IsEnabled = $false
    function Refresh-UI { $window.Dispatcher.Invoke([action]{}, [System.Windows.Threading.DispatcherPriority]::Render) }

    try {
        $BtnUpdateServer.Content = "RECHERCHE DU MOTEUR..."
        Refresh-UI

        $apiUrl  = "https://api.github.com/repos/tphakala/birdnet-go/releases/latest"
        $headers = @{ "User-Agent" = "PowerShell" }
        $release = Invoke-RestMethod -Uri $apiUrl -Headers $headers
        $latestTag = $release.tag_name

        $currentTag = if (Test-Path $VersionFile) { (Get-Content $VersionFile -Raw).Trim() } else { "0.0.0" }

        if ($latestTag -eq $currentTag) {
            $BtnUpdateServer.Content = "MOTEUR DÉJÀ À JOUR"
            Start-Sleep -Seconds 2
            $BtnUpdateServer.Content = "METTRE À JOUR LE MOTEUR (BIRDNET-GO)"
            $BtnUpdateServer.IsEnabled = $true
            return
        }

        $BtnUpdateServer.Content = "TÉLÉCHARGEMENT DU MOTEUR..."
        Refresh-UI

        $asset = $release.assets | Where-Object { $_.name -match "windows.*amd64.*\.tar\.gz" } | Select-Object -First 1
        if (-not $asset) { throw "Aucun asset trouvé" }

        $tempZip = Join-Path $env:TEMP "birdnet-update.tar.gz"
        Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $tempZip

        $BtnUpdateServer.Content = "EXTRACTION..."
        Refresh-UI

        $tempDir = Join-Path $env:TEMP "birdnet-update-extract"
        if (Test-Path $tempDir) { Remove-Item $tempDir -Recurse -Force }
        New-Item -ItemType Directory -Path $tempDir | Out-Null
        tar -xzf $tempZip -C $tempDir

        $newExe = Get-ChildItem -Path $tempDir -Filter "birdnet-go.exe" -Recurse | Select-Object -First 1
        if (-not $newExe) { throw "birdnet-go.exe introuvable" }

        $BtnUpdateServer.Content = "INSTALLATION DU MOTEUR..."
        Refresh-UI

        Get-Process -Name "birdnet-go" -ErrorAction SilentlyContinue | Stop-Process -Force
        Start-Sleep -Seconds 2

        Copy-Item -Path $newExe.FullName -Destination $ExePath -Force
        Set-Content -Path $VersionFile -Value $latestTag
        Remove-Item $tempZip -Force -ErrorAction SilentlyContinue
        Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue

        $BtnUpdateServer.Content = "REDÉMARRAGE DU SERVEUR..."
        Refresh-UI
        Start-Process -FilePath $ExePath -ArgumentList "serve" -WorkingDirectory $InstallDir -WindowStyle Hidden
        Start-Sleep -Seconds 2
        Update-UI

        $BtnUpdateServer.Content = "MOTEUR MIS À JOUR"
        Start-Sleep -Seconds 2
        $BtnUpdateServer.Content = "METTRE À JOUR LE MOTEUR (BIRDNET-GO)"
    }
    catch {
        $BtnUpdateServer.Content = "ERREUR MOTEUR"
        Start-Sleep -Seconds 2
        $BtnUpdateServer.Content = "METTRE À JOUR LE MOTEUR (BIRDNET-GO)"
    }
    finally {
        $BtnUpdateServer.IsEnabled = $true
    }
}
[void]$BtnUpdateServer.Add_Click({ Update-BirdNETGo })

# --- 8. LOGIQUE : MISE À JOUR DE L'INTERFACE (Frontend) ---
function Update-Interface {
    $BtnUpdateUI.IsEnabled = $false
    function Refresh-UI { $window.Dispatcher.Invoke([action]{}, [System.Windows.Threading.DispatcherPriority]::Render) }

    try {
        $BtnUpdateUI.Content = "RECHERCHE DE L'INTERFACE..."
        Refresh-UI

        # On interroge TON dépôt pour avoir le dernier installateur
        $apiUrl  = "https://api.github.com/repos/timeobonnin-prog/Installation-automatique-de-Birdnet-go/releases/latest"
        $headers = @{ "User-Agent" = "PowerShell" }
        $release = Invoke-RestMethod -Uri $apiUrl -Headers $headers
        
        $asset = $release.assets | Where-Object { $_.name -eq "BirdNET-Go-Windows.exe" } | Select-Object -First 1
        if (-not $asset) { throw "Installateur introuvable" }

        $BtnUpdateUI.Content = "TÉLÉCHARGEMENT DE L'INTERFACE..."
        Refresh-UI

        $tempInstaller = Join-Path $env:TEMP "BirdNET-Go-Update.exe"
        Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $tempInstaller

        $BtnUpdateUI.Content = "INSTALLATION EN COURS..."
        Refresh-UI

        # On affiche un message à l'utilisateur
        [System.Windows.MessageBox]::Show("L'installateur va se lancer pour mettre à jour l'interface. L'application actuelle va se fermer.", "Mise à jour de l'interface", "OK", "Information")

        # On lance l'installateur en mode silencieux et on quitte l'application actuelle
        Start-Process -FilePath $tempInstaller -ArgumentList "/VERYSILENT", "/SUPPRESSMSGBOXES", "/NORESTART"
        
        # On quitte cette instance pour que l'installateur puisse remplacer le fichier .exe
        Get-Process -Name "birdnet-go" -ErrorAction SilentlyContinue | Stop-Process -Force
        $trayIcon.Visible = $false
        [System.Windows.Application]::Current.Shutdown()
    }
    catch {
        $BtnUpdateUI.Content = "ERREUR INTERFACE"
        Start-Sleep -Seconds 2
        $BtnUpdateUI.Content = "METTRE À JOUR L'INTERFACE (CONTRÔLEUR)"
        $BtnUpdateUI.IsEnabled = $true
    }
}
[void]$BtnUpdateUI.Add_Click({ Update-Interface })

# --- 9. LOGIQUE DÉMARRAGE / ARRÊT ---
function Update-UI {
    $isRunning = $null -ne (Get-Process -Name "birdnet-go" -ErrorAction SilentlyContinue)
    if ($isRunning) {
        $TxtStatus.Text       = "EN LIGNE"
        $TxtStatus.Foreground = "#10B981"
        $StatusDot.Fill       = "#10B981"
        $BtnToggle.Content    = "ARRÊTER LE SERVEUR"
        $BtnToggle.Background = "#E11D48"
        $BtnOpen.IsEnabled    = $true
        $BtnOpen.Opacity      = 1
    }
    else {
        $TxtStatus.Text       = "HORS LIGNE"
        $TxtStatus.Foreground = "#EF4444"
        $StatusDot.Fill       = "#EF4444"
        $BtnToggle.Content    = "DÉMARRER LE SERVEUR"
        $BtnToggle.Background = "#10B981"
        $BtnOpen.IsEnabled    = $false
        $BtnOpen.Opacity      = 0.5
    }
}

[void]$BtnToggle.Add_Click({
    $isRunning = $null -ne (Get-Process -Name "birdnet-go" -ErrorAction SilentlyContinue)
    if ($isRunning) {
        Get-Process -Name "birdnet-go" -ErrorAction SilentlyContinue | Stop-Process -Force
    }
    else {
        if (Test-Path $ExePath) {
            Start-Process -FilePath $ExePath -ArgumentList "serve" -WorkingDirectory $InstallDir -WindowStyle Hidden
            Start-Sleep -Seconds 2
        }
    }
    Update-UI
})

# --- 10. SYSTEM TRAY ---
$trayIcon = New-Object System.Windows.Forms.NotifyIcon
$IconPath = Join-Path $InstallDir "icon.ico"
if (Test-Path $IconPath) {
    $trayIcon.Icon = New-Object System.Drawing.Icon($IconPath)
}
else {
    $trayIcon.Icon = [System.Drawing.SystemIcons]::Application
}
$trayIcon.Text = "BirdNET-Go Control Center"
$trayIcon.Visible = $true

$trayMenu = New-Object System.Windows.Forms.ContextMenuStrip

[void]$trayMenu.Items.Add("🌐 Ouvrir l'interface web").Add_Click({ Start-Process "http://localhost:8080" })
[void]$trayMenu.Items.Add("⚙️ Afficher le panneau").Add_Click({ $window.Show(); $window.WindowState = 'Normal'; $window.Activate() })
[void]$trayMenu.Items.Add("❌ Quitter complètement").Add_Click({
    Get-Process -Name "birdnet-go" -ErrorAction SilentlyContinue | Stop-Process -Force
    $trayIcon.Visible = $false
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

# --- 11. TIMER ---
$timer = New-Object System.Windows.Threading.DispatcherTimer
$timer.Interval = [TimeSpan]::FromMilliseconds(500)
[void]$timer.Add_Tick({ Update-UI })
$timer.Start()

# --- 12. DÉMARRAGE INITIAL ---
if (-not (Get-Process -Name "birdnet-go" -ErrorAction SilentlyContinue)) {
    if (Test-Path $ExePath) {
        Start-Process -FilePath $ExePath -ArgumentList "serve" -WorkingDirectory $InstallDir -WindowStyle Hidden
        Start-Sleep -Seconds 2
    }
}
Update-UI

[void]$trayIcon.ShowBalloonTip(3000, "BirdNET-Go", "Le panneau de contrôle est prêt.", [System.Windows.Forms.ToolTipIcon]::Info)
[void]$window.ShowDialog()
