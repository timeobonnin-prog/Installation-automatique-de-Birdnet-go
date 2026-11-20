using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Net.Http;
using System.Text.Json;
using System.Threading.Tasks;

namespace BirdNETGoControl
{
    public sealed class Detection
    {
        public string Species { get; set; } = "";
        public double Confidence { get; set; }
        public DateTime Time { get; set; }
    }

    public sealed class EngineStatus
    {
        public bool Reachable { get; set; }
        public double LatencyMs { get; set; }
    }

    public static class EngineApi
    {
        private static readonly HttpClient Http = new() { Timeout = TimeSpan.FromSeconds(4) };
        private static string? _cachedBase;

        private static string Root => $"http://localhost:{AppSettings.Current.ServerPort}";

        public static async Task<EngineStatus> PingAsync()
        {
            var sw = Stopwatch.StartNew();
            try
            {
                using var resp = await Http.GetAsync(Root + "/");
                sw.Stop();
                return new EngineStatus { Reachable = resp.IsSuccessStatusCode, LatencyMs = sw.Elapsed.TotalMilliseconds };
            }
            catch
            {
                sw.Stop();
                return new EngineStatus { Reachable = false, LatencyMs = -1 };
            }
        }

        private static async Task<string?> DiscoverBaseAsync()
        {
            var manual = AppSettings.Current.EngineApiBase;
            if (!string.IsNullOrWhiteSpace(manual)) return manual.TrimEnd('/');
            if (_cachedBase != null) return _cachedBase;

            foreach (var cand in new[] { "/api/v2", "/api/v1", "/api" })
            {
                try
                {
                    using var r = await Http.GetAsync(Root + cand + "/detections?limit=1");
                    if (r.IsSuccessStatusCode) { _cachedBase = cand; return cand; }
                }
                catch { }
            }
            return null;
        }

        public static async Task<List<Detection>> RecentAsync(int limit = 300)
        {
            var baseUrl = await DiscoverBaseAsync();
            var list = new List<Detection>();
            if (baseUrl == null) return list;

            try
            {
                using var r = await Http.GetAsync($"{Root}{baseUrl}/detections?limit={limit}");
                if (!r.IsSuccessStatusCode) return list;
                using var doc = JsonDocument.Parse(await r.Content.ReadAsStringAsync());

                JsonElement arr;
                if (doc.RootElement.ValueKind == JsonValueKind.Array) arr = doc.RootElement;
                else if (doc.RootElement.TryGetProperty("data", out var d) && d.ValueKind == JsonValueKind.Array) arr = d;
                else if (doc.RootElement.TryGetProperty("detections", out var d2) && d2.ValueKind == JsonValueKind.Array) arr = d2;
                else return list;

                foreach (var el in arr.EnumerateArray())
                {
                    var det = new Detection();
                    foreach (var p in el.EnumerateObject())
                    {
                        string n = p.Name.ToLowerInvariant();
                        if (n is "species" or "commonname" or "name") det.Species = p.Value.GetString() ?? "";
                        else if (n is "confidence" or "score" && p.Value.ValueKind == JsonValueKind.Number) det.Confidence = p.Value.GetDouble();
                        else if (n is "date" or "time" or "detectedat" or "createdat" && p.Value.ValueKind == JsonValueKind.String)
                        { if (DateTime.TryParse(p.Value.GetString(), out var t)) det.Time = t; }
                    }
                    if (!string.IsNullOrEmpty(det.Species)) list.Add(det);
                }
            }
            catch { }
            return list;
        }
    }
}
