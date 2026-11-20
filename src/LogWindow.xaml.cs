using System;
using System.IO;
using System.Linq;
using System.Windows;
using System.Windows.Controls;

namespace BirdNETGoControl
{
    public partial class LogWindow : System.Windows.Window
    {
        public LogWindow()
        {
            InitializeComponent();
            ApplyLanguage();
            FillFiles();
        }

        private void ApplyLanguage()
        {
            Title = Loc.T("LogsTitle");
            BtnRefresh.Content = Loc.T("LogsRefresh");
            BtnFolder.Content = Loc.T("LogsFolder");
            BtnCopy.Content = Loc.T("LogsCopy");
        }

        private void FillFiles()
        {
            CmbFiles.Items.Clear();
            try
            {
                var dir = App.LogDir;
                if (Directory.Exists(dir))
                {
                    foreach (var f in Directory.GetFiles(dir, "app_*.log")
                                 .OrderByDescending(x => File.GetLastWriteTime(x)))
                        CmbFiles.Items.Add(Path.GetFileName(f));
                }
            }
            catch { }

            if (CmbFiles.Items.Count > 0) CmbFiles.SelectedIndex = 0;
            else TxtLog.Text = Loc.T("LogsEmpty");
        }

        private void LoadSelected()
        {
            try
            {
                var name = CmbFiles.SelectedItem as string;
                if (string.IsNullOrEmpty(name)) { TxtLog.Text = Loc.T("LogsEmpty"); return; }
                var path = Path.Combine(App.LogDir, name);
                using var fs = new FileStream(path, FileMode.Open, FileAccess.Read, FileShare.ReadWrite);
                using var reader = new StreamReader(fs);
                TxtLog.Text = reader.ReadToEnd();
                TxtLog.ScrollToEnd();
            }
            catch (Exception ex)
            {
                TxtLog.Text = $"{Loc.T("LogsReadError")}\n{ex.Message}";
            }
        }

        private void OnFileChanged(object sender, SelectionChangedEventArgs e) => LoadSelected();
        private void OnRefresh(object sender, RoutedEventArgs e) => LoadSelected();

        private void OnFolder(object sender, RoutedEventArgs e)
        {
            try
            {
                if (!Directory.Exists(App.LogDir)) Directory.CreateDirectory(App.LogDir);
                System.Diagnostics.Process.Start(new System.Diagnostics.ProcessStartInfo(App.LogDir) { UseShellExecute = true });
            }
            catch { }
        }

        private void OnCopy(object sender, RoutedEventArgs e)
        {
            try { Clipboard.SetText(TxtLog.Text); } catch { }
        }
    }
}
