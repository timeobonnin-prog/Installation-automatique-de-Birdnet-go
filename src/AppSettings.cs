using System;
using System.IO;
using System.Text.Json;

namespace BirdNETGoControl
{
    // Options du CONTRÔLEUR uniquement. Aucun réglage moteur (config.yaml) ici.
    public class AppSettings
    {
        // Démarrage
        public bool LaunchAtStartup { get; set; } = false;
        public bool AutoStartServer { get; set; } = true;
        public bool MinimizeToTrayOnLaunch { get; set; } = false;

        // Gestion du processus birdnet-go.exe
        public bool AutoRestartOnCrash { get; set; } = true;
        public int MaxRestartAttempts { get; set; } = 3;
        public int RestartDelaySeconds { get; set; } = 2;
        public bool StopServerOnExit { get; set; } = true;

        // Mises à jour
        public int UpdateCheckIntervalHours { get; set; } = 24;
        public bool AllowNightlyUpdates { get; set; } = false;

        // Interface / confort
        public int ServerPort { get; set; } = 8080;
        public bool ShowBalloonNotifications { get; set; } = true;
        public int PurgeLogsOlderThanDays { get; set; } = 30;

        private static AppSettings _current;
        public static AppSettings Current => _current ??= Load();

        private static string SettingsPath => Path.Combine(
            Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData),
            "BirdNETGoControl", "settings.json");

        public static AppSettings Load()
        {
            try
            {
                if (File.Exists(SettingsPath))
                    return JsonSerializer.Deserialize<AppSettings>(File.ReadAllText(SettingsPath)) ?? new AppSettings();
            }
            catch { }
            return new AppSettings();
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
