using System;
using System.IO;
using System.IO.Compression;
using System.Text.Json;

namespace BirdNETGoControl
{
    public static class BackupHelper
    {
        public static string BackupDir => Path.Combine(App.DataDir, "backups");

        private sealed class Manifest
        {
            public string? EngineConfigPath { get; set; }
            public string Created { get; set; } = "";
        }

        public static string? Create()
        {
            try
            {
                if (!Directory.Exists(BackupDir)) Directory.CreateDirectory(BackupDir);
                string stamp = DateTime.Now.ToString("yyyyMMdd-HHmmss");
                string zip = Path.Combine(BackupDir, $"backup-{stamp}.zip");

                using var fs = File.Create(zip);
                using var archive = new ZipArchive(fs, ZipArchiveMode.Create);

                string settings = Path.Combine(App.DataDir, "settings.json");
                if (File.Exists(settings)) AddEntry(archive, settings, "settings.json");

                string? engine = PortHelper.FindEngineConfig();
                if (engine != null) AddEntry(archive, engine, "engine-config.yaml");

                string lang = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "LANGUAGE.txt");
                if (File.Exists(lang)) AddEntry(archive, lang, "LANGUAGE.txt");

                var entry = archive.CreateEntry("manifest.json");
                using (var w = new StreamWriter(entry.Open()))
                    w.Write(JsonSerializer.Serialize(new Manifest { Created = stamp, EngineConfigPath = engine }));

                return zip;
            }
            catch { return null; }
        }

        private static void AddEntry(ZipArchive archive, string source, string name)
        {
            var e = archive.CreateEntry(name);
            using var src = File.OpenRead(source);
            using var dst = e.Open();
            src.CopyTo(dst);
        }

        public static string? Latest()
        {
            try
            {
                if (!Directory.Exists(BackupDir)) return null;
                var files = Directory.GetFiles(BackupDir, "backup-*.zip");
                if (files.Length == 0) return null;
                Array.Sort(files, StringComparer.Ordinal);
                return files[files.Length - 1];
            }
            catch { return null; }
        }

        public static bool Restore(string zip)
        {
            try
            {
                using var archive = ZipFile.OpenRead(zip);

                string? engineTarget = null;
                var manifestEntry = archive.GetEntry("manifest.json");
                if (manifestEntry != null)
                {
                    using var r = new StreamReader(manifestEntry.Open());
                    engineTarget = JsonSerializer.Deserialize<Manifest>(r.ReadToEnd())?.EngineConfigPath;
                }
                if (engineTarget == null) engineTarget = PortHelper.FindEngineConfig();

                Extract(archive, "settings.json", Path.Combine(App.DataDir, "settings.json"));
                if (engineTarget != null) Extract(archive, "engine-config.yaml", engineTarget);
                Extract(archive, "LANGUAGE.txt", Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "LANGUAGE.txt"));
                return true;
            }
            catch { return false; }
        }

        private static void Extract(ZipArchive archive, string name, string target)
        {
            var e = archive.GetEntry(name);
            if (e == null) return;
            var dir = Path.GetDirectoryName(target);
            if (!string.IsNullOrEmpty(dir) && !Directory.Exists(dir)) Directory.CreateDirectory(dir);
            e.ExtractToFile(target, true);
        }
    }
}
