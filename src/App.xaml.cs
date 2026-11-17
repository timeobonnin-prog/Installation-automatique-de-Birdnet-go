using System;
using System.IO;

namespace BirdNETGoControl
{
    // Héritage explicite de WPF Application pour éviter le conflit avec WinForms
    public partial class App : System.Windows.Application
    {
        public static void Log(string message)
        {
            try
            {
                string appDir = System.AppDomain.CurrentDomain.BaseDirectory;
                string logDir = System.IO.Path.Combine(appDir, "logs");
                
                if (!System.IO.Directory.Exists(logDir))
                {
                    System.IO.Directory.CreateDirectory(logDir);
                }
                
                string logFile = System.IO.Path.Combine(logDir, $"app_{System.DateTime.Now:yyyyMMdd}.log");
                string logEntry = $"[{System.DateTime.Now:HH:mm:ss}] {message}{System.Environment.NewLine}";
                
                System.IO.File.AppendAllText(logFile, logEntry);
            }
            catch
            {
                // Échec silencieux pour ne jamais bloquer l'application à cause du logging
            }
        }
    }
}
