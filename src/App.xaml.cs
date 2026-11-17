using System;
using System.IO;
using System.Windows;

namespace BirdNETGoControl;

public partial class App : Application
{
    /// <summary>
    /// Méthode de journalisation centralisée pour l'application.
    /// </summary>
    public static void Log(string message)
    {
        try
        {
            // Détermine le répertoire de l'application
            string appDir = AppDomain.CurrentDomain.BaseDirectory;
            string logDir = Path.Combine(appDir, "logs");
            
            // Crée le dossier logs s'il n'existe pas
            if (!Directory.Exists(logDir))
            {
                Directory.CreateDirectory(logDir);
            }
            
            // Nom du fichier de log basé sur la date du jour
            string logFile = Path.Combine(logDir, $"app_{DateTime.Now:yyyyMMdd}.log");
            string logEntry = $"[{DateTime.Now:HH:mm:ss}] {message}{Environment.NewLine}";
            
            // Ajoute le message au fichier
            File.AppendAllText(logFile, logEntry);
        }
        catch
        {
            // En cas d'échec d'écriture (ex: permissions), on ignore silencieusement 
            // pour éviter de faire planter l'application à cause du système de log.
        }
    }
}
