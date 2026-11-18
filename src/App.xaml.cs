using System;
using System.IO;
using System.IO.Pipes;
using System.Threading;
using System.Threading.Tasks;

namespace BirdNETGoControl
{
    public partial class App : System.Windows.Application
    {
        private const string MutexName = "BirdNETGoControl_SingleInstance_Mutex";
        private const string PipeName = "BirdNETGoControl_SingleInstance_Pipe";

        private Mutex _mutex;

        // Dossier commun réglages + logs (inscriptible même sans admin)
        public static string DataDir => Path.Combine(
            Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData),
            "BirdNETGoControl");

        public static string LogDir => Path.Combine(DataDir, "logs");

        protected override void OnStartup(System.Windows.StartupEventArgs e)
        {
            _mutex = new Mutex(true, MutexName, out bool createdNew);

            if (!createdNew)
            {
                _ = NotifyExistingInstanceToShowAsync();
                Shutdown();
                return;
            }

            StartShowListener();
            base.OnStartup(e);
        }

        private async Task NotifyExistingInstanceToShowAsync()
        {
            try
            {
                using var client = new NamedPipeClientStream(".", PipeName, PipeDirection.Out);
                await client.ConnectAsync(2000);
                using var writer = new StreamWriter(client);
                await writer.WriteAsync("SHOW");
                await writer.FlushAsync();
            }
            catch { }
        }

        private void StartShowListener()
        {
            _ = Task.Run(async () =>
            {
                while (true)
                {
                    try
                    {
                        using var server = new NamedPipeServerStream(PipeName, PipeDirection.In, 1);
                        await server.WaitForConnectionAsync();
                        using var reader = new StreamReader(server);
                        string msg = await reader.ReadToEndAsync();
                        if (msg == "SHOW")
                            Dispatcher.Invoke(() => ShowExistingWindow());
                    }
                    catch { }
                    await Task.Delay(100);
                }
            });
        }

        private void ShowExistingWindow()
        {
            if (Current.MainWindow is MainWindow mw)
                mw.ShowWindow();
        }

        public static void Log(string message)
        {
            try
            {
                if (!Directory.Exists(LogDir)) Directory.CreateDirectory(LogDir);
                string logFile = Path.Combine(LogDir, $"app_{DateTime.Now:yyyyMMdd}.log");
                File.AppendAllText(logFile, $"[{DateTime.Now:HH:mm:ss}] {message}{Environment.NewLine}");
            }
            catch { }
        }
    }
}
