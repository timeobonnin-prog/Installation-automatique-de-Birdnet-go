using System;
using System.IO;
using System.Text.Json;

namespace BirdNETGoControl
{
    public class AppSettings
    {
        public string Language { get; set; } = "auto";

        public bool LaunchAtStartup { get; set; } = false;
        public bool AutoStartServer { get; set; } = true;
        public bool MinimizeToTrayOnLaunch { get; set; } = false;

        public bool AutoRestartOnCrash { get; set; } = true;
        public int MaxRestartAttempts { get; set; } = 3;
        public int RestartDelaySeconds { get; set; } = 2;
        public bool StopServerOnExit { get; set; } = true;

        public int UpdateCheckIntervalHours { get; set; } = 24;
        public bool AllowNightlyUpdates { get; set; } = false;

        public int ServerPort { get; set; } = 8080;
        public bool ShowBalloonNotifications { get; set; } = true;
        public int PurgeLogsOlderThanDays { get; set; } = 30;

        public bool VerifyUpdateHash { get; set; } = true;
        public bool RememberWindowPos { get; set; } = true;
        public double? WinLeft { get; set; } = null;
        public double? WinTop { get; set; } = null;

        // #9 raccourci global (défaut : Ctrl+Alt+B)
        public bool HotkeyEnabled { get; set; } = true;
        public int HotkeyModifiers { get; set; } = 3;   // MOD_ALT(1) | MOD_CONTROL(2)
        public int HotkeyVk { get; set; } = 0x42;       // 'B'

        private static AppSettings _current;
        public static AppSettings Current => _current ??= Load();

        public static AppSettings Reload() { _current = Load(); return _current; }

        private static string SettingsPath => Path.Combine(
            Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData),
            "BirdNETGoControl", "settings.json");

        public static AppSettings Load()
        {
            AppSettings inst;
            try
            {
                inst = File.Exists(SettingsPath)
                    ? JsonSerializer.Deserialize<AppSettings>(File.ReadAllText(SettingsPath)) ?? new AppSettings()
                    : new AppSettings();
            }
            catch { inst = new AppSettings(); }

            inst.ApplyInstallPortOverride();   // #10 : /PORT= de l'installateur
            return inst;
        }

        // Lit PORT_OVERRIDE.txt écrit par l'installateur (/PORT=), patche le moteur, puis se supprime
        private void ApplyInstallPortOverride()
        {
            try
            {
                var f = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "PORT_OVERRIDE.txt");
                if (!File.Exists(f)) return;
                if (int.TryParse(File.ReadAllText(f).Trim(), out int p) && p >= 1 && p <= 65535)
                {
                    ServerPort = p;
                    PortHelper.TrySetEnginePort(p);
                }
                File.Delete(f);
                Save();
            }
            catch { }
        }

        public void Save()
        {
            try
            {
                var dir = Path.GetDirectoryName(SettingsPath);
                if (!Directory.Exists(dir)) Directory.CreateDirectory(dir);
                File.WriteAllText(SettingsPath, JsonSerializer.Serialize(this, new JsonSerializerOptions { WriteIndented = true }));
            }
            catch (Exception ex) { App.Log($"Erreur sauvegarde réglages : {ex.Message}"); }

            ApplyStartupRegistration();
        }

        private void ApplyStartupRegistration()
        {
            try
            {
                using var key = Microsoft.Win32.Registry.CurrentUser.OpenSubKey(
                    @"Software\Microsoft\Windows\CurrentVersion\Run", true);
                if (key == null) return;

                if (LaunchAtStartup)
                {
                    string exe = Environment.ProcessPath ?? "";
                    if (!string.IsNullOrEmpty(exe)) key.SetValue("BirdNETGoControl", $"\"{exe}\"");
                }
                else
                {
                    key.DeleteValue("BirdNETGoControl", false);
                }
            }
            catch (Exception ex) { App.Log($"Erreur registre démarrage : {ex.Message}"); }
        }
    }
}
