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

        protected override void OnStartup(System.Windows.StartupEventArgs e)
        {
            _mutex = new Mutex(true, MutexName, out bool createdNew);

            if (!createdNew)
            {
                // Une instance existe déjà : on lui demande de s'afficher, puis on quitte.
                _ = NotifyExistingInstanceToShowAsync();
                Shutdown();
                return; // pas de base.OnStartup => aucune fenêtre créée
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
                string appDir = AppDomain.CurrentDomain.BaseDirectory;
                string logDir = Path.Combine(appDir, "logs");
                if (!Directory.Exists(logDir)) Directory.CreateDirectory(logDir);
                string logFile = Path.Combine(logDir, $"app_{DateTime.Now:yyyyMMdd}.log");
                File.AppendAllText(logFile, $"[{DateTime.Now:HH:mm:ss}] {message}{Environment.NewLine}");
            }
            catch { }
        }
    }
}
