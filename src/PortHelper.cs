using System;
using System.IO;
using System.Net.NetworkInformation;
using System.Text.RegularExpressions;

namespace BirdNETGoControl
{
    public static class PortHelper
    {
        public static bool IsFree(int port)
        {
            try
            {
                foreach (var l in IPGlobalProperties.GetIPGlobalProperties().GetActiveTcpListeners())
                    if (l.Port == port) return false;
                return true;
            }
            catch { return true; }
        }

        public static int FindFree(int preferred, int span = 10)
        {
            for (int i = 0; i < span; i++)
            {
                int p = preferred + i;
                if (p > 65535) break;
                if (IsFree(p)) return p;
            }
            return preferred;
        }

        public static string[] EngineConfigCandidates()
        {
            string app = AppDomain.CurrentDomain.BaseDirectory.TrimEnd('\\');
            string roam = Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData);
            string local = Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData);
            string all = Environment.GetFolderPath(Environment.SpecialFolder.CommonApplicationData);
            return new[]
            {
                Path.Combine(app, "config.yaml"),
                Path.Combine(roam, "birdnet-go", "config.yaml"),
                Path.Combine(local, "birdnet-go", "config.yaml"),
                Path.Combine(all, "birdnet-go", "config.yaml"),
            };
        }

        public static string? FindEngineConfig()
        {
            foreach (var c in EngineConfigCandidates())
                if (File.Exists(c)) return c;
            return null;
        }

        // Lit le port réel du moteur depuis son config.yaml ("port: 8080")
        public static int? GetEnginePort()
        {
            try
            {
                var path = FindEngineConfig();
                if (path == null) return null;
                foreach (var line in File.ReadLines(path))
                {
                    var t = line.Trim();
                    if (t.StartsWith("port:"))
                    {
                        if (int.TryParse(t.Substring(5).Trim(), out int p)) return p;
                    }
                }
            }
            catch { }
            return null;
        }

        // Réécrit la première ligne "port: <n>" du config.yaml du moteur
        public static bool TrySetEnginePort(int newPort)
        {
            try
            {
                var path = FindEngineConfig();
                if (path == null) return false;
                string text = File.ReadAllText(path);
                var rx = new Regex(@"(?m)^(\s*port:\s*)\d+");
                if (!rx.IsMatch(text)) return false;
                File.WriteAllText(path, rx.Replace(text, $"${{1}}{newPort}", 1));
                return true;
            }
            catch { return false; }
        }
    }
}
