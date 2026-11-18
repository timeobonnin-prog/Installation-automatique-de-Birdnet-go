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

using WpfApplication = System.Windows.Application;
using WpfMessageBox = System.Windows.MessageBox;
using WpfColor = System.Windows.Media.Color;

namespace BirdNETGoControl
{
    public partial class MainWindow : System.Windows.Window
    {
        private readonly string _installDir;
        private readonly string _exePath;
        private readonly string _uiVersionFile;
        private readonly string _engineVersionFile;
        private readonly WinForms.NotifyIcon _tray;
        private readonly DispatcherTimer _statusTimer;
        private readonly DispatcherTimer _updateTimer;

        private readonly HttpClient _http = new() { Timeout = TimeSpan.FromSeconds(10) };
        private readonly HttpClient _downloadHttp = new() { Timeout = TimeSpan.FromMinutes(5) };

        private int _crashCount = 0;
        private bool _wasRunning = false;
        private bool _shouldServerBeRunning = false;
        private DateTime _lastCrashTime = DateTime.MinValue;
        private DateTime _lastUpdateCheck = DateTime.MinValue;
        private bool _isQuitting = false;

        public MainWindow()
        {
            InitializeComponent();
            _installDir = AppDomain.CurrentDomain.BaseDirectory.TrimEnd('\\');
            _exePath = Path.Combine(_installDir, "birdnet-go.exe");
            _uiVersionFile = Path.Combine(_installDir, "UI_VERSION.txt");
            _engineVersionFile = Path.Combine(_installDir, "VERSION.txt");

            TitleBar.MouseLeftButtonDown += (_, _) => DragMove();

            _tray = new WinForms.NotifyIcon { Text = "BirdNET-Go", Visible = true };
            var iconPath = Path.Combine(_installDir, "icon.ico");
            _tray.Icon = File.Exists(iconPath) ? new System.Drawing.Icon(iconPath) : System.Drawing.SystemIcons.Application;

            var menu = new WinForms.ContextMenuStrip();
            menu.Items.Add("🌐 Ouvrir l'interface web", null, (_, _) => OpenWeb());
            menu.Items.Add("⚙️ Afficher le panneau", null, (_, _) => ShowWindow());
            menu.Items.Add("🔧 Réglages", null, (_, _) => { ShowWindow(); OpenSettings(); });
            menu.Items.Add("❌ Quitter", null, (_, _) => QuitAll());
            _tray.ContextMenuStrip = menu;
            _tray.DoubleClick += (_, _) => ShowWindow();

            _http.DefaultRequestHeaders.UserAgent.ParseAdd("BirdNET-Go-UI/1.0");
            _downloadHttp.DefaultRequestHeaders.UserAgent.ParseAdd("BirdNET-Go-UI/1.0");

            _statusTimer = new DispatcherTimer { Interval = TimeSpan.FromMilliseconds(500) };
            _statusTimer.Tick += (_, _) => UpdateUI();
            _statusTimer.Start();

            _updateTimer = new DispatcherTimer { Interval = TimeSpan.FromHours(24) };
            _updateTimer.Tick += async (_, _) => await CheckUpdatesAsync();
            _updateTimer.Start();

            PurgeOldLogs();
            ApplySettings();
            _ = CheckUpdatesAsync();

            Closing += (_, e) =>
            {
                if (!_isQuitting) { e.Cancel = true; Hide(); ShowTrayTip(); }
            };

            var s = AppSettings.Current;
            if (s.AutoStartServer && !IsServerRunning() && File.Exists(_exePath)) StartServer();
            if (s.MinimizeToTrayOnLaunch) Hide();

            UpdateUI();
        }

        private bool IsServerRunning() => Process.GetProcessesByName("birdnet-go").Length > 0;

        private void StartServer()
        {
            try
            {
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
            }
            catch (Exception ex) { App.Log($"Erreur démarrage : {ex.Message}"); }
        }

        private void StopServer()
        {
            try
            {
                _shouldServerBeRunning = false;
                foreach (var p in Process.GetProcessesByName("birdnet-go")) p.Kill();
                App.Log("Serveur arrêté.");
            }
            catch (Exception ex) { App.Log($"Erreur arrêt : {ex.Message}"); }
        }

        private void UpdateUI()
        {
            var isRunning = IsServerRunning();
            var s = AppSettings.Current;

            if (!isRunning && _shouldServerBeRunning)
            {
                if (_wasRunning)
                {
                    _crashCount++;
                    _lastCrashTime = DateTime.Now;
                    _wasRunning = false;
                    App.Log($"⚠️ Crash détecté ({_crashCount}/{s.MaxRestartAttempts})");
                    if (_crashCount > s.MaxRestartAttempts)
                    {
                        _shouldServerBeRunning = false;
                        App.Log("❌ Trop de crashs, arrêt des redémarrages.");
                    }
                }

                if (s.AutoRestartOnCrash && _crashCount >= 1 && _crashCount <= s.MaxRestartAttempts &&
                    (DateTime.Now - _lastCrashTime).TotalSeconds >= s.RestartDelaySeconds)
                {
                    StartServer();
                    _wasRunning = true;
                }
            }
            else if (isRunning) { _crashCount = 0; _wasRunning = true; }
            else { _wasRunning = false; }

            if (isRunning)
            {
                TxtStatus.Text = "EN LIGNE";
                TxtStatus.Foreground = new SolidColorBrush(WpfColor.FromRgb(16, 185, 129));
                StatusDot.Fill = new SolidColorBrush(WpfColor.FromRgb(16, 185, 129));
                BtnToggle.Content = "ARRÊTER LE SERVEUR";
                BtnToggle.Background = new SolidColorBrush(WpfColor.FromRgb(225, 29, 72));
                BtnOpen.IsEnabled = true;
                _tray.Text = "BirdNET-Go - En ligne";
            }
            else
            {
                TxtStatus.Text = "HORS LIGNE";
                TxtStatus.Foreground = new SolidColorBrush(WpfColor.FromRgb(239, 68, 68));
                StatusDot.Fill = new SolidColorBrush(WpfColor.FromRgb(239, 68, 68));
                BtnToggle.Content = "DÉMARRER LE SERVEUR";
                BtnToggle.Background = new SolidColorBrush(WpfColor.FromRgb(16, 185, 129));
                BtnOpen.IsEnabled = false;
                _tray.Text = "BirdNET-Go - Hors ligne";
            }
        }

        private void ApplySettings()
        {
            var s = AppSettings.Current;
            _updateTimer.Interval = TimeSpan.FromHours(Math.Max(1, s.UpdateCheckIntervalHours));
        }

        private void OpenSettings()
        {
            var win = new SettingsWindow { Owner = this };
            if (win.ShowDialog() == true)
            {
                ApplySettings();
                _lastUpdateCheck = DateTime.MinValue;
                _ = CheckUpdatesAsync();
                UpdateUI();
            }
        }

        private void OnSettings(object sender, RoutedEventArgs e) => OpenSettings();

        private void PurgeOldLogs()
        {
            try
            {
                int days = AppSettings.Current.PurgeLogsOlderThanDays;
                if (days <= 0) return;
                var dir = App.LogDir;
                if (!Directory.Exists(dir)) return;
                foreach (var f in Directory.GetFiles(dir, "app_*.log"))
                    if (File.GetLastWriteTime(f) < DateTime.Now.AddDays(-days)) File.Delete(f);
            }
            catch { }
        }

        private async Task<GitHubRelease?> GetTargetReleaseAsync()
        {
            var s = AppSettings.Current;
            if (s.AllowNightlyUpdates)
            {
                var list = await _http.GetFromJsonAsync<List<GitHubRelease>>(
                    "https://api.github.com/repos/timeobonnin-prog/Installation-automatique-de-Birdnet-go/releases?per_page=15");
                return list?.Find(r => r.prerelease && (r.tag_name ?? "").StartsWith("nightly-"))
                       ?? list?.Find(r => !r.prerelease);
            }
            return await _http.GetFromJsonAsync<GitHubRelease>(
                "https://api.github.com/repos/timeobonnin-prog/Installation-automatique-de-Birdnet-go/releases/latest");
        }

        private async Task CheckUpdatesAsync()
        {
            var s = AppSettings.Current;
            if (s.UpdateCheckIntervalHours <= 0)
            {
                TxtUpdateStatus.Text = "Vérification désactivée";
                TxtUpdateStatus.Foreground = new SolidColorBrush(WpfColor.FromRgb(108, 112, 134));
                return;
            }
            if (_lastUpdateCheck != DateTime.MinValue && (DateTime.Now - _lastUpdateCheck).TotalHours < s.UpdateCheckIntervalHours) return;
            _lastUpdateCheck = DateTime.Now;

            try
            {
                var release = await GetTargetReleaseAsync();
                var latestTag = release?.tag_name ?? "";

                var uiVersion = File.Exists(_uiVersionFile) ? File.ReadAllText(_uiVersionFile).Trim() : "0.0.0";
                var engineVersion = File.Exists(_engineVersionFile) ? File.ReadAllText(_engineVersionFile).Trim() : "0.0.0";
                TxtUiVersion.Text = $"v{uiVersion}";
                TxtEngineVersion.Text = $"v{engineVersion}";

                if (!string.IsNullOrEmpty(latestTag) && uiVersion != latestTag)
                {
                    BtnUpdate.Content = "⚡ MISE À JOUR DISPO";
                    BtnUpdate.Background = new SolidColorBrush(WpfColor.FromRgb(16, 185, 129));
                    TxtUpdateStatus.Text = $"Nouveau : {latestTag}";
                    TxtUpdateStatus.Foreground = new SolidColorBrush(WpfColor.FromRgb(245, 158, 11));
                }
                else
                {
                    BtnUpdate.Content = "⬇️ MISE À JOUR COMPLÈTE (UI + MOTEUR)";
                    BtnUpdate.Background = new SolidColorBrush(WpfColor.FromRgb(139, 92, 246));
                    TxtUpdateStatus.Text = "Aucune mise à jour";
                    TxtUpdateStatus.Foreground = new SolidColorBrush(WpfColor.FromRgb(16, 185, 129));
                }
            }
            catch
            {
                TxtUpdateStatus.Text = "Vérification impossible";
                TxtUpdateStatus.Foreground = new SolidColorBrush(WpfColor.FromRgb(239, 68, 68));
            }
        }

        private async void OnUpdate(object sender, RoutedEventArgs e)
        {
            BtnUpdate.IsEnabled = false;
            BtnUpdate.Content = "MISE À JOUR...";

            try
            {
                var release = await GetTargetReleaseAsync();
                var asset = release?.assets?.FirstOrDefault(a => a.name == "BirdNET-Go-Windows.exe");
                if (asset is null) throw new Exception("Installateur introuvable");

                var installer = Path.Combine(Path.GetTempPath(), "BirdNET-Go-Update.exe");
                using (var dl = await _downloadHttp.GetAsync(asset.browser_download_url))
                {
                    dl.EnsureSuccessStatusCode();
                    await using var fs = File.Create(installer);
                    await dl.Content.CopyToAsync(fs);
                }

                var result = WpfMessageBox.Show(
                    "L'application va se fermer pour installer la mise à jour. Continuer ?",
                    "Mise à jour", MessageBoxButton.YesNo, MessageBoxImage.Question);
                if (result != MessageBoxResult.Yes) return;

                StopServer();
                _tray.Visible = false;

                Process.Start(new ProcessStartInfo(installer)
                {
                    Arguments = "/VERYSILENT /SUPPRESSMSGBOXES /NORESTART",
                    UseShellExecute = true
                });

                _isQuitting = true;
                WpfApplication.Current.Shutdown();
            }
            catch (Exception ex)
            {
                App.Log($"Update error: {ex.Message}");
                BtnUpdate.Content = "ERREUR";
                await Task.Delay(2000);
            }
            finally
            {
                if (!_isQuitting)
                {
                    BtnUpdate.Content = "⬇️ MISE À JOUR COMPLÈTE (UI + MOTEUR)";
                    BtnUpdate.IsEnabled = true;
                }
            }
        }

        private void OnMinimize(object sender, RoutedEventArgs e) => WindowState = WindowState.Minimized;
        private void OnClose(object sender, RoutedEventArgs e) { Hide(); ShowTrayTip(); }
        private void OnOpen(object sender, RoutedEventArgs e) => OpenWeb();
        private void OpenWeb() => Process.Start(new ProcessStartInfo($"http://localhost:{AppSettings.Current.ServerPort}") { UseShellExecute = true });

        private void OnToggle(object sender, RoutedEventArgs e)
        {
            if (IsServerRunning()) StopServer(); else StartServer();
            UpdateUI();
        }

        public void ShowWindow()
        {
            Show();
            WindowState = WindowState.Normal;
            Activate();
            Topmost = true;
            Topmost = false;
        }

        private void ShowTrayTip()
        {
            if (AppSettings.Current.ShowBalloonNotifications)
                _tray.ShowBalloonTip(3000, "BirdNET-Go", "L'app tourne en arrière-plan.", WinForms.ToolTipIcon.Info);
        }

        private void QuitAll()
        {
            _isQuitting = true;
            if (AppSettings.Current.StopServerOnExit) StopServer();
            _tray.Visible = false;
            _tray.Dispose();
            WpfApplication.Current.Shutdown();
        }
    }

    public class GitHubRelease
    {
        public string? tag_name { get; set; }
        public bool prerelease { get; set; }
        public List<GitHubAsset>? assets { get; set; }
    }

    public class GitHubAsset
    {
        public string? name { get; set; }
        public string? browser_download_url { get; set; }
    }
}
