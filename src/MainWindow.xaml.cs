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
                    if (_crashCount > s.Max
