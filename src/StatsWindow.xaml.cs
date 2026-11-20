using System;
using System.Collections.Generic;
using System.Globalization;
using System.IO;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows;
using System.Windows.Media;
using System.Windows.Media.Animation;
using Microsoft.Win32;

namespace BirdNETGoControl
{
    public partial class StatsWindow : Window
    {
        private List<Detection> _dets = new();

        public StatsWindow()
        {
            InitializeComponent();
            ApplyLanguage();
            Loaded += async (_, _) => await RefreshAsync();
        }

        private void ApplyLanguage()
        {
            Title = Loc.T("StatsTitle");
            TabDash.Header = Loc.T("TabDash");
            TabStats.Header = Loc.T("TabStats");
            BtnRefresh.Content = Loc.T("Refresh");
            BtnExport.Content = Loc.T("ExportCsv");
            TxtSparkTitle.Text = Loc.T("SparkTitle");
            TxtTopTitle.Text = Loc.T("Top5Title");
        }

        private async Task RefreshAsync()
        {
            var status = await EngineApi.PingAsync();
            _dets = await EngineApi.RecentAsync(300);

            if (status.Reachable)
            {
                PulseDot.Fill = new SolidColorBrush(Color.FromRgb(166, 227, 161));
                StartPulse();
                TxtListening.Text = Loc.T("Listening");
                TxtLatency.Text = string.Format(Loc.T("Latency"), status.LatencyMs.ToString("0"));
            }
            else
            {
                StopPulse();
                PulseDot.Fill = new SolidColorBrush(Color.FromRgb(243, 138, 168));
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

        // R1 : sparkline 24 h
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

        // R2 : top 5 espèces
        private void BuildTop()
        {
            var top = _dets.GroupBy(d => d.Species)
                .OrderByDescending(g => g.Count())
                .Take(5)
                .Select((g, i) => $"{i + 1}. {g.Key} — {g.Count()}")
                .ToList();
            TxtTop.Text = top.Count == 0 ? Loc.T("NoData") : string.Join("\n", top);
        }

        // R4 : pastille qui pulse
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

        private void OnRefresh(object sender, RoutedEventArgs e) => _ = RefreshAsync();

        // R3 : export CSV
        private void OnExport(object sender, RoutedEventArgs e)
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
                sb.AppendLine($"{d.Time:yyyy-MM-dd HH:mm:ss};{d.SpeciusSafe()};{d.Confidence.ToString("0.00", CultureInfo.InvariantCulture)}");
            try { File.WriteAllText(dlg.FileName, sb.ToString(), Encoding.UTF8); } catch { }
        }
    }

    internal static class DetectionCsv
    {
        public static string SpeciusSafe(this Detection d) => (d.Species ?? "").Replace(';', ',');
    }
}
