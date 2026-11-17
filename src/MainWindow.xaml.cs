using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Net.Http;
using System.Net.Http.Json;
using System.Threading.Tasks;
using System.Windows;
using System.Windows.Media;
using System.Windows.Threading;
using WinForms = System.Windows.Forms;

// Alias explicites pour éviter les conflits entre WPF et WinForms
using Application = System.Windows.Application;
using MessageBox = System.Windows.MessageBox;
using Color = System.Windows.Media.Color;

namespace BirdNETGoControl;

public partial class MainWindow : Window
{
    private readonly string _installDir;
    private readonly string _exePath;
    private readonly string _uiVersionFile;
    private readonly WinForms.NotifyIcon _tray;
    private readonly DispatcherTimer _statusTimer;
    private readonly DispatcherTimer _updateTimer;
    
    // Separate HTTP clients: one for quick API calls (5s), one for large downloads (5min)
    private readonly HttpClient _http = new() { Timeout = TimeSpan.FromSeconds(5) };
    private readonly HttpClient _downloadHttp = new() { Timeout = TimeSpan.FromMinutes(5) };
    
    private int _crashCount = 0;
    private bool _wasRunning = false;
    private bool _shouldServerBeRunning = false; // Tracks intended state to prevent restart after explicit stop
    private DateTime _lastUpdateCheck = DateTime.MinValue;
    private bool _isQuitting = false;

    public MainWindow()
    {
        InitializeComponent();
        _installDir = AppDomain.CurrentDomain.BaseDirectory.TrimEnd('\\');
        _exePath = Path.Combine(_installDir, "birdnet-go.exe");
        _uiVersionFile = Path.Combine(_installDir, "UI_VERSION.txt");

        TitleBar.MouseLeftButtonDown += (_, _) => DragMove();

        // Tray icon is now always visible while the app runs, preventing user lockout
        _tray = new WinForms.NotifyIcon { Text = "BirdNET-Go", Visible = true };
        var iconPath = Path.Combine(_installDir, "icon.ico");
        _tray.Icon = File.Exists(iconPath)
            ? new System.Drawing.Icon(iconPath)
            : System.Drawing.SystemIcons.Application;

        var menu = new WinForms.ContextMenuStrip();
        menu.Items.Add("🌐 Ouvrir l'interface web", null, (_, _) => OpenWeb());
        menu.Items.Add("⚙️ Afficher le panneau", null, (_, _) => ShowWindow());
        menu.Items.Add("❌ Quitter", null, (_, _) => QuitAll());
        _tray.ContextMenuStrip = menu;
        _tray.DoubleClick += (_, _) => ShowWindow();

        // FIX: Set User-Agent to prevent GitHub API 403 Forbidden errors
        _http.DefaultRequestHeaders.UserAgent.ParseAdd("BirdNET-Go-UI/1.0");
        _downloadHttp.DefaultRequestHeaders.UserAgent.ParseAdd("BirdNET-Go-UI/1.0");

        _statusTimer = new DispatcherTimer { Interval = TimeSpan.FromMilliseconds(500) };
        _statusTimer.Tick += (_, _) => UpdateUI();
        _statusTimer.Start();

        _updateTimer = new DispatcherTimer { Interval = TimeSpan.FromMinutes(60) };
        _updateTimer.Tick += async (_, _) => await CheckUpdatesAsync();
        _updateTimer.Start();
        _ = CheckUpdatesAsync();

        Closing += (_, e) => 
        { 
            if (!_isQuitting) { e.Cancel = true; Hide(); ShowTrayTip(); }
        };

        if (File.Exists(_exePath))
        {
            _shouldServerBeRunning = true;
            StartServer();
        }

        UpdateUI();
    }

    private bool IsServerRunning() => Process.GetProcessesByName("birdnet-go").Length > 0;

    private void StartServer()
    {
        try {
            Process.Start(new ProcessStartInfo
            {
                FileName = _exePath,
                Arguments = "serve",
                WorkingDirectory = _installDir,
                WindowStyle = ProcessWindowStyle.Hidden,
                CreateNoWindow = true
            });
            _shouldServerBeRunning = true;
            App.Log("Serveur démarré.");
        } catch (Exception ex) { App.Log($"Erreur démarrage : {ex.Message}"); }
    }

    private void StopServer()
    {
        try {
            _shouldServerBeRunning = false; // FIX: Explicit stop, prevents auto-restart loop
            foreach (var p in Process.GetProcessesByName("birdnet-go")) p.Kill();
            App.Log("Serveur arrêté.");
        } catch (Exception ex) { App.Log($"Erreur arrêt : {ex.Message}"); }
    }

    private void UpdateUI()
    {
        var isRunning = IsServerRunning();

        // FIX: Advanced crash recovery logic
        if (!isRunning && _shouldServerBeRunning)
        {
            if (_wasRunning) // It was running and now it's not -> genuine crash
            {
                _crashCount++;
                App.Log($"⚠️ Crash détecté ({_crashCount}/3)");
            }
            
            if (_crashCount <= 3)
            {
                StartServer();
                _wasRunning = true; // Expect it to run next tick; if it fails instantly, it counts as another crash attempt
            }
            else
            {
                _shouldServerBeRunning = false;
                App.Log("❌ 3 crashs consécutifs, arrêt des redémarrages.");
            }
        }
        else if (isRunning)
        {
            _crashCount = 0; // FIX: Reset count ONLY when stably running
            _wasRunning = true;
        }
        else
        {
            _wasRunning = false;
        }

        if (isRunning)
        {
            TxtStatus.Text = "EN LIGNE";
            TxtStatus.Foreground = new SolidColorBrush(Color.FromRgb(16, 185, 129));
            StatusDot.Fill = new SolidColorBrush(Color.FromRgb(16, 185, 129));
            BtnToggle.Content = "ARRÊTER LE SERVEUR";
            BtnToggle.Background = new SolidColorBrush(Color.FromRgb(225, 29, 72));
            BtnOpen.IsEnabled = true;
            _tray.Text = "BirdNET-Go - En ligne";
        }
        else
        {
            TxtStatus.Text = "HORS LIGNE";
            TxtStatus.Foreground = new SolidColorBrush(Color.FromRgb(239, 68, 68));
            StatusDot.Fill = new SolidColorBrush(Color.FromRgb(239, 68, 68));
            BtnToggle.Content = "DÉMARRER LE SERVEUR";
            BtnToggle.Background = new SolidColorBrush(Color.FromRgb(16, 185, 129));
            BtnOpen.IsEnabled = false;
            _tray.Text = "BirdNET-Go - Hors ligne";
        }
        // FIX: Removed _tray.Visible = false here. Tray stays accessible.
    }

    private async Task CheckUpdatesAsync()
    {
        if ((DateTime.Now - _lastUpdateCheck).TotalMinutes < 30) return;
        _lastUpdateCheck = DateTime.Now;

        try
        {
            var release = await _http.GetFromJsonAsync<GitHubRelease>(
                "https://api.github.com/repos/timeobonnin-prog/Installation-automatique-de-Birdnet-go/releases/latest");
            var latestTag = release?.tag_name ?? "";
            var localVersion = File.Exists(_uiVersionFile) ? File.ReadAllText(_uiVersionFile).Trim() : "0.0.0";

            if (localVersion != latestTag && !string.IsNullOrEmpty(latestTag))
            {
                BtnUpdate.Content = "⚡ NOUVELLE VERSION DISPO !";
                BtnUpdate.Background = new SolidColorBrush(Color.FromRgb(16, 185, 129));
                TxtUpdateStatus.Text = $"Mise à jour : {latestTag}";
                TxtUpdateStatus.Foreground = new SolidColorBrush(Color.FromRgb(245, 158, 11));
            }
            else
            {
                BtnUpdate.Content = "METTRE À JOUR BIRDNET-GO";
                BtnUpdate.Background = new SolidColorBrush(Color.FromRgb(139, 92, 246));
                TxtUpdateStatus.Text = $"À jour ({localVersion})";
                TxtUpdateStatus.Foreground = new SolidColorBrush(Color.FromRgb(16, 185, 129));
            }
        }
        catch
        {
            TxtUpdateStatus.Text = "Vérification impossible";
            TxtUpdateStatus.Foreground = new SolidColorBrush(Color.FromRgb(239, 68, 68));
        }
    }

    private void OnMinimize(object sender, RoutedEventArgs e) => WindowState = WindowState.Minimized;
    private void OnClose(object sender, RoutedEventArgs e) { Hide(); ShowTrayTip(); }
    private void OnOpen(object sender, RoutedEventArgs e) => OpenWeb();
    private void OpenWeb() => Process.Start(new ProcessStartInfo("http://localhost:8080") { UseShellExecute = true });

    private void OnToggle(object sender, RoutedEventArgs e)
    {
        if (IsServerRunning()) StopServer();
        else StartServer();
        UpdateUI();
    }

    private async void OnUpdate(object sender, RoutedEventArgs e)
    {
        BtnUpdate.IsEnabled = false;
        BtnUpdate.Content = "MISE À JOUR...";
        
        try
        {
            var release = await _http.GetFromJsonAsync<GitHubRelease>(
                "https://api.github.com/repos/timeobonnin-prog/Installation-automatique-de-Birdnet-go/releases/latest");

            var asset = release?.assets?.FirstOrDefault(a => a.name == "BirdNET-Go-Windows.exe");
            if (asset is null) throw new Exception("Installateur introuvable");

            var installer = Path.Combine(Path.GetTempPath(), "BirdNET-Go-Update.exe");
            
            // FIX: Use dedicated download client with 5-minute timeout
            using (var dl = await _downloadHttp.GetAsync(asset.browser_download_url))
            {
                dl.EnsureSuccessStatusCode();
                await using var fs = File.Create(installer);
                await dl.Content.CopyToAsync(fs);
            }

            var result = MessageBox.Show(
                "L'application va se fermer pour installer la mise à jour. Continuer ?",
                "Mise à jour", MessageBoxButton.YesNo, MessageBoxImage.Question);

            if (result != MessageBoxResult.Yes) return; // User cancelled

            StopServer();
            _tray.Visible = false;

            Process.Start(new ProcessStartInfo(installer)
            {
                Arguments = "/VERYSILENT /SUPPRESSMSGBOXES /NORESTART",
                UseShellExecute = true
            });

            _isQuitting = true;
            Application.Current.Shutdown();
        }
        catch (Exception ex)
        {
            App.Log($"Update error: {ex.Message}");
            BtnUpdate.Content = "ERREUR";
            await Task.Delay(2000);
        }
        finally
        {
            // FIX: Always restore button state if we are not quitting
            if (!_isQuitting)
            {
                BtnUpdate.Content = "METTRE À JOUR BIRDNET-GO";
                BtnUpdate.IsEnabled = true;
            }
        }
    }

    private void ShowWindow() { Show(); WindowState = WindowState.Normal; Activate(); }
    private void ShowTrayTip() => _tray.ShowBalloonTip(3000, "BirdNET-Go", "L'app tourne en arrière-plan.", WinForms.ToolTipIcon.Info);
    
    private void QuitAll()
    {
        _isQuitting = true;
        StopServer();
        _tray.Visible = false;
        Application.Current.Shutdown();
    }
}

public class GitHubRelease
{
    public string? tag_name { get; set; }
    public List<GitHubAsset>? assets { get; set; }
}

public class GitHubAsset
{
    public string? name { get; set; }
    public string? browser_download_url { get; set; }
}
