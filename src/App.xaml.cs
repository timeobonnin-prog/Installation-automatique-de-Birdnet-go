using System.Windows;
using System.IO;

namespace BirdNETGoControl;

public partial class App : Application
{
    public static string LogFile { get; } = Path.Combine(
        Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
        "BirdNET-Go", "tray.log");

    protected override void OnStartup(StartupEventArgs e)
    {
        Directory.CreateDirectory(Path.GetDirectoryName(LogFile)!);
        AppDomain.CurrentDomain.UnhandledException += (s, ex) =>
            Log($"[FATAL] {ex.ExceptionObject}");
        DispatcherUnhandledException += (s, ex) =>
        {
            Log($"[UI-CRASH] {ex.Exception}");
            ex.Handled = true; // Empêche le crash
        };
        Log("Application démarrée.");
        base.OnStartup(e);
    }

    public static void Log(string msg)
    {
        try {
            File.AppendAllText(LogFile, $"[{DateTime.Now:yyyy-MM-dd HH:mm:ss}] {msg}\n");
        } catch { }
    }
}
