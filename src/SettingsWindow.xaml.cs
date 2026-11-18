using System;
using System.Diagnostics;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Input;

namespace BirdNETGoControl
{
    public partial class SettingsWindow : System.Windows.Window
    {
        public SettingsWindow()
        {
            InitializeComponent();
            var s = AppSettings.Current;

            ChkStartup.IsChecked = s.LaunchAtStartup;
            ChkAutoStart.IsChecked = s.AutoStartServer;
            ChkMinimize.IsChecked = s.MinimizeToTrayOnLaunch;
            ChkAutoRestart.IsChecked = s.AutoRestartOnCrash;
            ChkStopOnExit.IsChecked = s.StopServerOnExit;
            ChkNightly.IsChecked = s.AllowNightlyUpdates;
            ChkBalloon.IsChecked = s.ShowBalloonNotifications;
            TxtPort.Text = s.ServerPort.ToString();

            SelectByTag(CmbAttempts, s.MaxRestartAttempts);
            SelectByTag(CmbDelay, s.RestartDelaySeconds);
            SelectByTag(CmbUpdateFreq, s.UpdateCheckIntervalHours);
            SelectByTag(CmbPurge, s.PurgeLogsOlderThanDays);
        }

        private static void SelectByTag(ComboBox cmb, int value)
        {
            foreach (ComboBoxItem item in cmb.Items)
                if (item.Tag?.ToString() == value.ToString()) { cmb.SelectedItem = item; return; }
            cmb.SelectedIndex = 0;
        }

        private static int ReadTag(ComboBox cmb, int fallback)
        {
            return cmb.SelectedItem is ComboBoxItem item && int.TryParse(item.Tag?.ToString(), out int v) ? v : fallback;
        }

        private void OnDrag(object sender, MouseButtonEventArgs e) => DragMove();

        private void OnOpenWeb(object sender, RoutedEventArgs e)
        {
            int port = int.TryParse(TxtPort.Text, out int p) ? p : 8080;
            Process.Start(new ProcessStartInfo($"http://localhost:{port}") { UseShellExecute = true });
        }

        private void OnCancel(object sender, RoutedEventArgs e) { DialogResult = false; Close(); }

        private void OnSave(object sender, RoutedEventArgs e)
        {
            if (!int.TryParse(TxtPort.Text, out int port) || port < 1 || port > 65535)
            {
                System.Windows.MessageBox.Show("Port invalide (1–65535).", "Réglages", MessageBoxButton.OK, MessageBoxImage.Warning);
                return;
            }

            var s = AppSettings.Current;
            s.LaunchAtStartup = ChkStartup.IsChecked == true;
            s.AutoStartServer = ChkAutoStart.IsChecked == true;
            s.MinimizeToTrayOnLaunch = ChkMinimize.IsChecked == true;
            s.AutoRestartOnCrash = ChkAutoRestart.IsChecked == true;
            s.MaxRestartAttempts = ReadTag(CmbAttempts, 3);
            s.RestartDelaySeconds = ReadTag(CmbDelay, 2);
            s.StopServerOnExit = ChkStopOnExit.IsChecked == true;
            s.UpdateCheckIntervalHours = ReadTag(CmbUpdateFreq, 24);
            s.AllowNightlyUpdates = ChkNightly.IsChecked == true;
            s.ServerPort = port;
            s.ShowBalloonNotifications = ChkBalloon.IsChecked == true;
            s.PurgeLogsOlderThanDays = ReadTag(CmbPurge, 30);
            s.Save();

            DialogResult = true;
            Close();
        }
    }
}
