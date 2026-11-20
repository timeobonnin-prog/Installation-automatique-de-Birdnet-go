using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Globalization;
using System.IO;
using System.Linq;
using System.Net.Http;
using System.Net.Http.Json;
using System.Runtime.InteropServices;
using System.Security.Cryptography;
using System.Text;
using System.Threading.Tasks;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Interop;
using System.Windows.Media;
using System.Windows.Media.Animation;
using System.Windows.Threading;
using Microsoft.Win32;
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
        private readonly HttpClient _downloadHttp = new() { Timeout = TimeSpan.FromMinutes(10) };

        private int _crashCount = 0;
        private bool _wasRunning = false;
        private bool _shouldServerBeRunning = false;
        private DateTime _lastCrashTime = DateTime.MinValue;
        private DateTime _lastUpdateCheck = DateTime.MinValue;
        private bool _isQuitting = false;

        private UpdateInfo? _pendingUpdate;
        private GitHubRelease? _cachedRelease;
        private DateTime _cachedReleaseAt = DateTime.MinValue;

        private List<Detection> _dets = new();

        private const string UpdateJsonUrl =
            "https://timeobonnin-prog.github.io/Installation-automatique-de-Birdnet-go/update.json";

        private const int WM_HOTKEY = 0x0312;
        private const int HOTKEY_ID = 9001;
        private HwndSource? _hwndSource;

        [DllImport("user32.dll")]
        private static extern bool RegisterHotKey(IntPtr hWnd, int id, uint fsModifiers, uint vk);
        [DllImport("user32.dll")]
        private static extern bool UnregisterHotKey(IntPtr hWnd, int id);

        public MainWindow()
        {
            Loc.Init(AppSettings.Current.Language);
            InitializeComponent();

            _installDir = AppDomain.CurrentDomain.BaseDirectory.TrimEnd('\\');
            _exePath = Path.Combine(_installDir, "birdnet-go.exe");
            _uiVersionFile = Path.Combine(_installDir, "UI_VERSION.txt");
            _engineVersionFile = Path.Combine(_installDir, "VERSION.txt");

            RestoreWindowPosition();

            TitleBar.MouseLeftButtonDown += (_, _) => DragMove();

            _tray = new WinForms.NotifyIcon { Text = "BirdNET-Go", Visible = true };
            var iconPath = Path.Combine(_installDir, "icon.ico");
            _tray.Icon = File.Exists(iconPath) ? new System.Drawing.Icon(iconPath) : System.Drawing.SystemIcons.Application;
            BuildTrayMenu();
            _tray.DoubleClick += (_, _) => ShowWindow();

            _http.DefaultRequestHeaders.UserAgent.ParseAdd("BirdNET-Go-UI/1.0");
            _downloadHttp.DefaultRequestHeaders.UserAgent.ParseAdd("BirdNET-Go-UI/1.0");

            _statusTimer = new DispatcherTimer { Interval = TimeSpan.FromMilliseconds(500) };
            _statusTimer.Tick += async (_, _) => await TickAsync();
            _statusTimer.Start();

            _updateTimer = new DispatcherTimer { Interval = TimeSpan.FromHours(24) };
            _updateTimer.Tick += async (_, _) => await CheckUpdatesAsync();
            _updateTimer.Start();

            PurgeOldLogs();
            CleanupTempUpdates();   // ✅ Correctif 2 : nettoie les vieux installateurs
            ApplySettings();
            RefreshLocalVersions();
            ApplyLanguage();
            SetNav(NavControl);
            _ = CheckUpdatesAsync();

            Closing += (_, e) =>
            {
                SaveWindowPosition();
                if (!_isQuitting) { e.Cancel = true; Hide(); ShowTrayTip(); }
            };

            var s = AppSettings.Current;
            if (s.AutoStartServer && !IsServerRunning() && File.Exists(_exePath))
            {
                EnsurePort();   // ✅ Correctif 3 : détection processus fantômes
                StartServer();
            }
            if (s.MinimizeToTrayOnLaunch) Hide();

            UpdateUI();
        }

        // ✅ Correctif 2 : nettoyage des anciens installateurs en cache
        private void CleanupTempUpdates()
        {
            try
            {
                string tempDir = Path.GetTempPath();
                var oldFiles = Directory.GetFiles(tempDir, "BirdNET-Go-Update-*.exe");
                foreach (var file in oldFiles)
                {
                    try { File.Delete(file); } catch { /* Ignorer si verrouillé */ }
                }
            }
            catch { }
        }

        // ---------------- Navigation par onglets ----------------
        private void SetNav(Button active)
        {
            NavControl.Tag = null;
            NavResults.Tag = null;
            NavStats.Tag = null;
            active.Tag = "sel";

            PanelControl.Visibility = active == NavControl ? Visibility.Visible : Visibility.Collapsed;
            PanelResults.Visibility = active == NavResults ? Visibility.Visible : Visibility.Collapsed;
            PanelStats.Visibility = active == NavStats ? Visibility.Visible : Visibility.Collapsed;
        }

        private void OnNavControl(object sender, RoutedEventArgs e) => SetNav(NavControl);
        private void OnNavResults(object sender, RoutedEventArgs e) { SetNav(NavResults); _ = RefreshStatsAsync(); }
        private void OnNavStats(object sender, RoutedEventArgs e) { SetNav(NavStats); _ = RefreshStatsAsync(); }
        private void OnRefreshStats(object sender, RoutedEventArgs e) => _ = RefreshStatsAsync();

        // ---------------- Résultats / Statistiques ----------------
        private async Task RefreshStatsAsync()
        {
            var status = await EngineApi.PingAsync();
            _dets = await EngineApi.RecentAsync(300);

            if (status.Reachable)
            {
                PulseDot.Fill = new SolidColorBrush(WpfColor.FromRgb(166, 227, 161));
                StartPulse();
                TxtListening.Text = Loc.T("Listening");
                TxtLatency.Text = string.Format(Loc.T("Latency"), status.LatencyMs.ToString("0"));
            }
            else
            {
                StopPulse();
                PulseDot.Fill = new SolidColorBrush(WpfColor.FromRgb(243, 138, 168));
                TxtListening.Text = Loc.T("NotReachable");
                TxtLatency.Text = "";
            }

            var today = _dets.Where(d => d.Time.Date == DateTime.Today).ToList();
            TxtToday.Text = string.Format(Loc.T("TodayCount"), today.Count);

            var last = _dets.OrderByDescending(d => d.Time).FirstOrDefault();
            TxtLast.Text = last == null
                ? Loc.T("NoData")
                : string.Format(Loc.T("LastDetection"), last.Species, last.Time.ToString("HH:mm"), (last.Confidence * 100).ToString("0"));

            TxtApiNote.Text = (_dets.Count == 0 && status.Reachable) ? Loc.T("ApiUndetected") : "";

            BuildSpark(today);
            BuildTop();
        }

        private void BuildSpark(List<Detection> today)
        {
            var hours = new int[24];
            foreach (var d in today) hours[d.Time.Hour]++;
            int max = hours.Length == 0 ? 1 : hours.Max();
            if (max == 0) max = 1;

            var pts = new PointCollection();
            for (int i = 0; i < 24; i++)
                pts.Add(new Point(i * (100.0 / 23.0), 100 - (hours[i] * 100.0 / max)));
            Spark.Points = pts;
        }

        private void BuildTop()
        {
            var top = _dets.GroupBy(d => d.Species)
                .OrderByDescending(g => g.Count())
                .Take(5)
                .Select((g, i) => $"{i + 1}. {g.Key} — {g.Count()}")
                .ToList();
            TxtTop.Text = top.Count == 0 ? Loc.T("NoData") : string.Join("\n", top);
        }

        private void StartPulse()
        {
            var anim = new DoubleAnimation(1.0, 0.25, TimeSpan.FromMilliseconds(700))
            {
                AutoReverse = true,
                RepeatBehavior = RepeatBehavior.Forever
            };
            PulseDot.BeginAnimation(UIElement.OpacityProperty, anim);
        }

        private void StopPulse() => PulseDot.BeginAnimation(UIElement.OpacityProperty, null);

        private void OnExportCsv(object sender, RoutedEventArgs e)
        {
            if (_dets.Count == 0) return;
            var dlg = new SaveFileDialog
            {
                FileName = $"detections-{DateTime.Now:yyyyMMdd-HHmm}.csv",
                Filter = "CSV|*.csv"
            };
            if (dlg.ShowDialog() != true) return;

            var sb = new StringBuilder();
            sb.AppendLine("date;espece;confiance");
            foreach (var d in _dets.OrderBy(x => x.Time))
                sb.AppendLine($"{d.Time:yyyy-MM-dd HH:mm:ss};{(d.Species ?? "").Replace(';', ',')};{d.Confidence.ToString("0.00", CultureInfo.InvariantCulture)}");
            try { File.WriteAllText(dlg.FileName, sb.ToString(), Encoding.UTF8); } catch { }
        }

        // ---------------- #9 Raccourci global ----------------
        protected override void OnSourceInitialized(EventArgs e)
        {
            base.OnSourceInitialized(e);
            var helper = new WindowInteropHelper(this);
            _hwndSource = HwndSource.FromHwnd(helper.Handle);
            _hwndSource?.AddHook(WndProc);
            RegisterHotkey();
        }

        private void RegisterHotkey()
        {
            if (_hwndSource == null) return;
            var s = AppSettings.Current;
            UnregisterHotKey(_hwndSource.Handle, HOTKEY_ID);
            if (s.HotkeyEnabled)
                RegisterHotKey(_hwndSource.Handle, HOTKEY_ID, (uint)s.HotkeyModifiers, (uint)s.HotkeyVk);
        }

        private IntPtr WndProc(IntPtr hwnd, int msg, IntPtr wParam, IntPtr lParam, ref bool handled)
        {
            if (msg == WM_HOTKEY && wParam.ToInt32() == HOTKEY_ID)
            {
                ShowWindow();
                handled = true;
            }
            return IntPtr.Zero;
        }

        // ---------------- #6 Port auto + Correctif 3 : détection processus fantômes ----------------
        private void EnsurePort()
        {
            try
            {
                var s = AppSettings.Current;

                // 1. Vérifier si le processus est déjà en cours d'exécution
                var processes = Process.GetProcessesByName("birdnet-go");
                if (processes.Length > 0)
                {
                    // Le moteur tourne déjà, on synchronise juste l'UI
                    _shouldServerBeRunning = true;
                    return;
                }

                // 2. Si le processus n'est pas là, mais que le port est occupé, c'est un conflit externe
                if (!PortHelper.IsFree(s.ServerPort))
                {
                    int free = PortHelper.FindFree(s.ServerPort + 1);
                    if (free != s.ServerPort)
                    {
                        int old = s.ServerPort;
                        s.ServerPort = free;
                        s.Save();
                        PortHelper.TrySetEnginePort(free);
                        App.Log($"⚠️ Port {old} occupé par une autre application → bascule sur {free}.");
                    }
                }
            }
            catch { }
        }

        // ---------------- #14 Position fenêtre ----------------
        private void RestoreWindowPosition()
        {
            var s = AppSettings.Current;
            if (!s.RememberWindowPos || !s.WinLeft.HasValue || !s.WinTop.HasValue) return;

            double x = s.WinLeft.Value, y = s.WinTop.Value;
            var area = SystemParameters.WorkArea;
            if (x >= area.Left - 50 && x < area.Right - 50 && y >= area.Top - 50 && y < area.Bottom - 50)
            {
                WindowStartupLocation = WindowStartupLocation.Manual;
                Left = x;
                Top = y;
            }
        }

        private void SaveWindowPosition()
        {
            var s = AppSettings.Current;
            if (!s.RememberWindowPos || WindowState != WindowState.Normal) return;
            s.WinLeft = Left;
            s.WinTop = Top;
            s.Save();
        }

        // ---------------- Langue ----------------
        private void ApplyLanguage()
        {
            NavControl.Content = Loc.T("NavControl");
            NavResults.Content = Loc.T("TabDash");
            NavStats.Content = Loc.T("TabStats");

            TxtLblController.Text = Loc.T("LblController");
            TxtLblEngine.Text = Loc.T("LblEngine");
            TxtUpdateHint.Text = Loc.T("UpdateHint");
            BtnOpen.Content = Loc.T("BtnOpenWeb");
            BtnUpdate.Content = Loc.T("BtnUpdate");

            BtnRefresh.Content = Loc.T("Refresh");
            TxtSparkTitle.Text = Loc.T("SparkTitle");
            TxtTopTitle.Text = Loc.T("Top5Title");
            BtnExport.Content = Loc.T("ExportCsv");

            BuildTrayMenu();
        }

        private void BuildTrayMenu()
        {
            var old = _tray.ContextMenuStrip;
            var menu = new WinForms.ContextMenuStrip();
            menu.Items.Add(Loc.T("BtnOpenWeb"), null, (_, _) => OpenWeb());
            menu.Items.Add(Loc.T("TrayShow"), null, (_, _) => ShowWindow());
            menu.Items.Add(Loc.T("TrayStats"), null, (_, _) => { ShowWindow(); SetNav(NavResults); _ = RefreshStatsAsync(); });
            menu.Items.Add(Loc.T("TrayLogs"), null, (_, _) => OpenLogs());
            menu.Items.Add(Loc.T("TrayBackup"), null, (_, _) => DoBackup());
            menu.Items.Add(Loc.T("TrayRestore"), null, (_, _) => DoRestore());
            menu.Items.Add(Loc.T("TraySettings"), null, (_, _) => { ShowWindow(); OpenSettings(); });
            menu.Items.Add(Loc.T("TrayQuit"), null, (_, _) => QuitAll());
            _tray.ContextMenuStrip = menu;
            old?.Dispose();
        }

        // ---------------- Résultats / logs / backup ----------------
        private void OpenStats()
        {
            SetNav(NavResults);
            _ = RefreshStatsAsync();
        }

        private void OpenLogs()
        {
            var win = new LogWindow { Owner = this };
            win.Show();
        }

        private void Tip(string text, WinForms.ToolTipIcon icon)
        {
            if (AppSettings.Current.ShowBalloonNotifications)
                _tray.ShowBalloonTip(3000, "BirdNET-Go", text, icon);
        }

        private void DoBackup()
        {
            var zip = BackupHelper.Create();
            if (zip == null) { App.Log("Backup échoué."); Tip(Loc.T("BackupFail"), WinForms.ToolTipIcon.Warning); return; }
            App.Log($"Backup créé : {zip}");
            Tip(Loc.T("BackupDone"), WinForms.ToolTipIcon.Info);
        }

        private void DoRestore()
        {
            var zip = BackupHelper.Latest();
            if (zip == null || !BackupHelper.Restore(zip))
            {
                App.Log("Restore échoué.");
                Tip(Loc.T("RestoreFail"), WinForms.ToolTipIcon.Warning);
                return;
            }

            AppSettings.Reload();
            Loc.Init(AppSettings.Current.Language);
            ApplySettings();
            ApplyLanguage();
            RegisterHotkey();
            UpdateUI();
            App.Log($"Restore effectué : {zip}");
            Tip(Loc.T("RestoreDone"), WinForms.ToolTipIcon.Info);
        }

        // ---------------- Serveur ----------------
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

        // Le scan de processus tourne HORS thread UI => plus de freeze au drag
        private async Task TickAsync()
        {
            bool isRunning = await Task.Run(() => Process.GetProcessesByName("birdnet-go").Length > 0);
            ApplyStatus(isRunning);
        }

        private void UpdateUI() => _ = TickAsync();

        private void ApplyStatus(bool isRunning)
        {
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
                TxtStatus.Text = Loc.T("StatusOnline");
                TxtStatus.Foreground = new SolidColorBrush(WpfColor.FromRgb(16, 185, 129));
                StatusDot.Fill = new SolidColorBrush(WpfColor.FromRgb(16, 185, 129));
                BtnToggle.Content = Loc.T("BtnStop");
                BtnToggle.Background = new SolidColorBrush(WpfColor.FromRgb(225, 29, 72));
                BtnOpen.IsEnabled = true;
                _tray.Text = Loc.T("TrayOnline");
            }
            else
            {
                TxtStatus.Text = Loc.T("StatusOffline");
                TxtStatus.Foreground = new SolidColorBrush(WpfColor.FromRgb(239, 68, 68));
                StatusDot.Fill = new SolidColorBrush(WpfColor.FromRgb(239, 68, 68));
                BtnToggle.Content = Loc.T("BtnStart");
                BtnToggle.Background = new SolidColorBrush(WpfColor.FromRgb(16, 185, 129));
                BtnOpen.IsEnabled = false;
                _tray.Text = Loc.T("TrayOffline");
            }
        }

        // ---------------- Réglages ----------------
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
                Loc.Init(AppSettings.Current.Language);
                ApplySettings();
                ApplyLanguage();
                RegisterHotkey();
                _lastUpdateCheck = DateTime.MinValue;
                _ = CheckUpdatesAsync();
                UpdateUI();
            }
            else
            {
                Loc.Init(AppSettings.Current.Language);
                ApplyLanguage();
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

        // ---------------- Versions ----------------
        private static string FormatVersion(string raw)
        {
            var v = (raw ?? "").Trim().TrimStart('v', 'V');
            return string.IsNullOrEmpty(v) ? "v0.0.0" : "v" + v;
        }

        private void RefreshLocalVersions()
        {
            try
            {
                var ui = File.Exists(_uiVersionFile) ? File.ReadAllText(_uiVersionFile) : "";
                var eng = File.Exists(_engineVersionFile) ? File.ReadAllText(_engineVersionFile) : "";
                TxtUiVersion.Text = FormatVersion(ui);
                TxtEngineVersion.Text = FormatVersion(eng);
            }
            catch { }
        }

        // ---------------- Mises à jour (canal statique, sans quota API) ----------------
        private async Task<UpdateInfo?> FetchUpdateInfoAsync()
        {
            if (!AppSettings.Current.AllowNightlyUpdates)
            {
                try
                {
                    var info = await _http.GetFromJsonAsync<UpdateInfo>(UpdateJsonUrl + "?t=" + DateTime.UtcNow.Ticks);
                    if (!string.IsNullOrEmpty(info?.tag) && !string.IsNullOrEmpty(info?.url))
                        return info;
                }
                catch { }
            }

            try
            {
                var release = await GetTargetReleaseAsync();
                var asset = release?.assets?.FirstOrDefault(a => a.name == "BirdNET-Go-Windows.exe");
                if (release != null && asset != null)
                    return new UpdateInfo
                    {
                        tag = release.tag_name,
                        url = asset.browser_download_url,
                        sha256 = asset.digest?.StartsWith("sha256:") == true ? asset.digest.Substring(7) : null,
                        prerelease = release.prerelease
                    };
            }
            catch { }
            return null;
        }

        private async Task<GitHubRelease?> GetTargetReleaseAsync()
        {
            if (_cachedRelease != null && (DateTime.Now - _cachedReleaseAt).TotalMinutes < 5)
                return _cachedRelease;

            var s = AppSettings.Current;
            GitHubRelease? release;
            if (s.AllowNightlyUpdates)
            {
                var list = await _http.GetFromJsonAsync<List<GitHubRelease>>(
                    "https://api.github.com/repos/timeobonnin-prog/Installation-automatique-de-Birdnet-go/releases?per_page=15");
                release = list?.Find(r => r.prerelease && (r.tag_name ?? "").StartsWith("nightly-"))
                          ?? list?.Find(r => !r.prerelease);
            }
            else
            {
                release = await _http.GetFromJsonAsync<GitHubRelease>(
                    "https://api.github.com/repos/timeobonnin-prog/Installation-automatique-de-Birdnet-go/releases/latest");
            }

            _cachedRelease = release;
            _cachedReleaseAt = DateTime.Now;
            return release;
        }

        private static string Sha256OfFile(string path)
        {
            using var fs = File.OpenRead(path);
            using var sha = SHA256.Create();
            return Convert.ToHexString(sha.ComputeHash(fs)).ToLowerInvariant();
        }

        private async Task CheckUpdatesAsync()
        {
            RefreshLocalVersions();

            var s = AppSettings.Current;
            if (s.UpdateCheckIntervalHours <= 0)
            {
                TxtUpdateStatus.Text = Loc.T("UpdateDisabled");
                TxtUpdateStatus.Foreground = new SolidColorBrush(WpfColor.FromRgb(108, 112, 134));
                return;
            }
            if (_lastUpdateCheck != DateTime.MinValue && (DateTime.Now - _lastUpdateCheck).TotalHours < s.UpdateCheckIntervalHours) return;
            _lastUpdateCheck = DateTime.Now;

            try
            {
                var info = await FetchUpdateInfoAsync();
                _pendingUpdate = info;
                var latestTag = info?.tag ?? "";
                var uiVersion = File.Exists(_uiVersionFile) ? File.ReadAllText(_uiVersionFile).Trim() : "0.0.0";

                bool upToDate = string.IsNullOrEmpty(latestTag) ||
                                FormatVersion(uiVersion) == FormatVersion(latestTag);

                if (!upToDate)
                {
                    BtnUpdate.Content = Loc.T("BtnUpdateAvailable");
                    BtnUpdate.Background = new SolidColorBrush(WpfColor.FromRgb(16, 185, 129));
                    TxtUpdateStatus.Text = string.Format(Loc.T("UpdateNew"), FormatVersion(latestTag));
                    TxtUpdateStatus.Foreground = new SolidColorBrush(WpfColor.FromRgb(245, 158, 11));
                }
                else
                {
                    BtnUpdate.Content = Loc.T("BtnUpdate");
                    BtnUpdate.Background = new SolidColorBrush(WpfColor.FromRgb(139, 92, 246));
                    TxtUpdateStatus.Text = Loc.T("UpdateNone");
                    TxtUpdateStatus.Foreground = new SolidColorBrush(WpfColor.FromRgb(16, 185, 129));
                }
            }
            catch
            {
                TxtUpdateStatus.Text = Loc.T("UpdateImpossible");
                TxtUpdateStatus.Foreground = new SolidColorBrush(WpfColor.FromRgb(239, 68, 68));
            }
        }

        private async void OnUpdate(object sender, RoutedEventArgs e)
        {
            BtnUpdate.IsEnabled = false;
            BtnUpdate.Content = Loc.T("BtnUpdating");

            try
            {
                var info = _pendingUpdate ?? await FetchUpdateInfoAsync();
                if (info?.url == null) throw new Exception("Canal de mise à jour injoignable");

                string installer = Path.Combine(Path.GetTempPath(), $"BirdNET-Go-Update-{DateTime.Now:yyyyMMdd-HHmmss}.exe");

                using (var dl = await _downloadHttp.GetAsync(info.url, HttpCompletionOption.ResponseHeadersRead))
                {
                    dl.EnsureSuccessStatusCode();
                    await using var fs = File.Create(installer);
                    await dl.Content.CopyToAsync(fs);
                }

                if (AppSettings.Current.VerifyUpdateHash && !string.IsNullOrEmpty(info.sha256))
                {
                    string expected = info.sha256.ToLowerInvariant();
                    string actual = await Task.Run(() => Sha256OfFile(installer));   // fond => pas de freeze
                    if (expected != actual)
                    {
                        try { File.Delete(installer); } catch { }
                        throw new Exception("SHA-256 invalide (fichier corrompu ou incomplet)");
                    }
                    App.Log("SHA-256 de l'installateur vérifié.");
                }

                var result = WpfMessageBox.Show(
                    Loc.T("UpdateConfirmText"), Loc.T("UpdateConfirmTitle"),
                    MessageBoxButton.YesNo, MessageBoxImage.Question);
                if (result != MessageBoxResult.Yes)
                {
                    try { File.Delete(installer); } catch { }
                    return;
                }

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
                App.Log($"Update error: {ex.GetType().Name}: {ex.Message}");
                TxtUpdateStatus.Text = ex.Message;
                TxtUpdateStatus.Foreground = new SolidColorBrush(WpfColor.FromRgb(239, 68, 68));
                BtnUpdate.Content = Loc.T("BtnError");
                await Task.Delay(4000);
            }
            finally
            {
                if (!_isQuitting)
                {
                    BtnUpdate.Content = Loc.T("BtnUpdateAvailable");
                    BtnUpdate.Background = new SolidColorBrush(WpfColor.FromRgb(16, 185, 129));
                    BtnUpdate.IsEnabled = true;
                }
            }
        }

        // ---------------- UI / tray ----------------
        private void OnMinimize(object sender, RoutedEventArgs e) => WindowState = WindowState.Minimized;
        private void OnClose(object sender, RoutedEventArgs e) { SaveWindowPosition(); Hide(); ShowTrayTip(); }
        private void OnOpen(object sender, RoutedEventArgs e) => OpenWeb();
        private void OpenWeb() => Process.Start(new ProcessStartInfo($"http://localhost:{AppSettings.Current.ServerPort}") { UseShellExecute = true });

        private void OnToggle(object sender, RoutedEventArgs e)
        {
            if (IsServerRunning()) StopServer();
            else { EnsurePort(); StartServer(); }
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

        private void ShowTrayTip() => Tip(Loc.T("TrayTipText"), WinForms.ToolTipIcon.Info);

        private void QuitAll()
        {
            _isQuitting = true;
            SaveWindowPosition();
            if (_hwndSource != null) UnregisterHotKey(_hwndSource.Handle, HOTKEY_ID);
            if (AppSettings.Current.StopServerOnExit) StopServer();
            _tray.Visible = false;
            _tray.Dispose();
            WpfApplication.Current.Shutdown();
        }
    }

    public class UpdateInfo
    {
        public string? tag { get; set; }
        public string? url { get; set; }
        public string? sha256 { get; set; }
        public bool prerelease { get; set; }
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
        public string? digest { get; set; }
    }
}
