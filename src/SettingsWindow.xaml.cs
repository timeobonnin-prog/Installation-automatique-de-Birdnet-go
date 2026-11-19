using System;
using System.Diagnostics;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Input;

namespace BirdNETGoControl
{
    public partial class SettingsWindow : System.Windows.Window
    {
        private bool _loading = true;

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

            FillLanguageCombo(s.Language);
            FillNumericCombos(s);
            ApplyLanguage();

            _loading = false;
        }

        private void FillLanguageCombo(string selected)
        {
            CmbLanguage.Items.Clear();
            CmbLanguage.Items.Add(new ComboBoxItem { Content = Loc.T("LangAuto"), Tag = "auto" });
            foreach (var code in Loc.Codes)
                CmbLanguage.Items.Add(new ComboBoxItem { Content = Loc.DisplayName(code), Tag = code });

            foreach (ComboBoxItem it in CmbLanguage.Items)
                if ((it.Tag?.ToString() ?? "") == selected) { CmbLanguage.SelectedItem = it; break; }
            if (CmbLanguage.SelectedItem == null) CmbLanguage.SelectedIndex = 0;
        }

        private void FillNumericCombos(AppSettings s)
        {
            CmbUpdateFreq.Items.Clear();
            AddItem(CmbUpdateFreq, Loc.T("Never"), 0);
            AddItem(CmbUpdateFreq, "6 h", 6);
            AddItem(CmbUpdateFreq, "24 h", 24);
            AddItem(CmbUpdateFreq, "7 " + Loc.T("DaysShort"), 168);
            SelectByTag(CmbUpdateFreq, s.UpdateCheckIntervalHours);

            CmbPurge.Items.Clear();
            AddItem(CmbPurge, Loc.T("Never"), 0);
            AddItem(CmbPurge, "7 " + Loc.T("DaysShort"), 7);
            AddItem(CmbPurge, "30 " + Loc.T("DaysShort"), 30);
            AddItem(CmbPurge, "90 " + Loc.T("DaysShort"), 90);
            SelectByTag(CmbPurge, s.PurgeLogsOlderThanDays);

            SelectByTag(CmbAttempts, s.MaxRestartAttempts);
            SelectByTag(CmbDelay, s.RestartDelaySeconds);
        }

        private static void AddItem(ComboBox cmb, string text, int value)
            => cmb.Items.Add(new ComboBoxItem { Content = text, Tag = value.ToString() });

        private void ApplyLanguage()
        {
            Title = Loc.T("SettingsWindowTitle");
            TxtSettingsTitle.Text = Loc.T("SettingsTitle");
            TxtIntro.Text = Loc.T("SettingsIntro");

            TxtGrpLanguage.Text = Loc.T("GrpLanguage");
            TxtLblLanguage.Text = Loc.T("LblLanguage");

            TxtGrpStartup.Text = Loc.T("GrpStartup");
            ChkStartup.Content = Loc.T("ChkStartup");
            ChkAutoStart.Content = Loc.T("ChkAutoStart");
            ChkMinimize.Content = Loc.T("ChkMinimize");

            TxtGrpServer.Text = Loc.T("GrpServer");
            ChkAutoRestart.Content = Loc.T("ChkAutoRestart");
            TxtLblAttempts.Text = Loc.T("LblAttempts");
            TxtLblDelay.Text = Loc.T("LblDelay");
            ChkStopOnExit.Content = Loc.T("ChkStopOnExit");

            TxtGrpUpdates.Text = Loc.T("GrpUpdates");
            TxtLblFreq.Text = Loc.T("LblFreq");
            ChkNightly.Content = Loc.T("ChkNightly");

            TxtGrpUi.Text = Loc.T("GrpUi");
            TxtLblPort.Text = Loc.T("LblPort");
            TxtLblPurge.Text = Loc.T("LblPurge");
            ChkBalloon.Content = Loc.T("ChkBalloon");

            TxtGrpDetection.Text = Loc.T("GrpDetection");
            TxtDetectionHint.Text = Loc.T("DetectionHint");
            BtnOpenEngineWeb.Content = Loc.T("BtnOpenEngineWeb");

            BtnCancel.Content = Loc.T("BtnCancel");
            BtnSave.Content = Loc.T("BtnSave");
        }

        // Aperçu immédiat : toute la fenêtre se retraduit quand on change la langue
        private void OnLanguageChanged(object sender, SelectionChangedEventArgs e)
        {
            if (_loading) return;
            string code = (CmbLanguage.SelectedItem as ComboBoxItem)?.Tag?.ToString() ?? "auto";
            Loc.Init(code);
            ApplyLanguage();
            FillNumericCombos(AppSettings.Current);
            FillLanguageCombo(code);
        }

        private static void SelectByTag(ComboBox cmb, int value)
        {
            foreach (ComboBoxItem item in cmb.Items)
                if (item.Tag?.ToString() == value.ToString()) { cmb.SelectedItem = item; return; }
            cmb.SelectedIndex = 0;
        }

        private static int ReadTag(ComboBox cmb, int fallback)
            => cmb.SelectedItem is ComboBoxItem item && int.TryParse(item.Tag?.ToString(), out int v) ? v : fallback;

        private void OnDrag(object sender, MouseButtonEventArgs e) => DragMove();

        private void OnOpenWeb(object sender, RoutedEventArgs e)
        {
            int port = int.TryParse(TxtPort.Text, out int p) ? p : 8080;
            Process.Start(new ProcessStartInfo($"http://localhost:{port}") { UseShellExecute = true });
        }

        private void OnCancel(object sender, RoutedEventArgs e)
        {
            Loc.Init(AppSettings.Current.Language);   // restaure la langue enregistrée
            DialogResult = false;
            Close();
        }

        private void OnSave(object sender, RoutedEventArgs e)
        {
            if (!int.TryParse(TxtPort.Text, out int port) || port < 1 || port > 65535)
            {
                System.Windows.MessageBox.Show(Loc.T("PortInvalid"), Loc.T("SettingsWindowTitle"),
                    MessageBoxButton.OK, MessageBoxImage.Warning);
                return;
            }

            var s = AppSettings.Current;
            s.Language = (CmbLanguage.SelectedItem as ComboBoxItem)?.Tag?.ToString() ?? "auto";
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

            Loc.Init(s.Language);
            DialogResult = true;
            Close();
        }
    }
}
