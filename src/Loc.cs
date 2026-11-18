using System;
using System.Collections.Generic;
using System.Globalization;
using System.IO;

namespace BirdNETGoControl
{
    // Traduction légère : ordre des colonnes = fr, en, de, es
    public static class Loc
    {
        public static readonly string[] Codes = { "fr", "en", "de", "es" };
        public static string Current { get; private set; } = "fr";

        public static void Init(string pref)
        {
            if (string.IsNullOrWhiteSpace(pref) || pref == "auto")
            {
                // 1) langue choisie dans l'installateur (LANGUAGE.txt), 2) langue Windows, 3) anglais
                string forced = "";
                try
                {
                    var f = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "LANGUAGE.txt");
                    if (File.Exists(f)) forced = File.ReadAllText(f).Trim().ToLowerInvariant();
                }
                catch { }

                string sys = CultureInfo.CurrentUICulture.TwoLetterISOLanguageName.ToLowerInvariant();
                string pick = Array.IndexOf(Codes, forced) >= 0 ? forced : sys;
                Current = Array.IndexOf(Codes, pick) >= 0 ? pick : "en";
            }
            else
            {
                Current = Array.IndexOf(Codes, pref) >= 0 ? pref : "en";
            }
        }

        public static string T(string key)
        {
            if (!Map.TryGetValue(key, out var vals)) return key;
            int i = Array.IndexOf(Codes, Current);
            if (i < 0) i = 1;
            return string.IsNullOrEmpty(vals[i]) ? vals[1] : vals[i];
        }

        public static string DisplayName(string code) => code switch
        {
            "fr" => "Français",
            "en" => "English",
            "de" => "Deutsch",
            "es" => "Español",
            _ => code
        };

        //                            fr                        en                        de                        es
        private static readonly Dictionary<string, string[]> Map = new()
        {
            ["StatusOnline"]        = new[] { "EN LIGNE", "ONLINE", "ONLINE", "EN LÍNEA" },
            ["StatusOffline"]       = new[] { "HORS LIGNE", "OFFLINE", "OFFLINE", "SIN CONEXIÓN" },
            ["BtnStart"]            = new[] { "DÉMARRER LE SERVEUR", "START SERVER", "SERVER STARTEN", "INICIAR SERVIDOR" },
            ["BtnStop"]             = new[] { "ARRÊTER LE SERVEUR", "STOP SERVER", "SERVER STOPPEN", "DETENER SERVIDOR" },
            ["BtnOpenWeb"]          = new[] { "🌐 Ouvrir l'interface web", "🌐 Open web interface", "🌐 Weboberfläche öffnen", "🌐 Abrir interfaz web" },
            ["BtnUpdate"]           = new[] { "METTRE À JOUR", "UPDATE", "AKTUALISIEREN", "ACTUALIZAR" },
            ["BtnUpdateAvailable"]  = new[] { "MAJ DISPONIBLE", "UPDATE AVAILABLE", "UPDATE VERFÜGBAR", "ACTUALIZACIÓN DISPONIBLE" },
            ["BtnUpdating"]         = new[] { "MISE À JOUR...", "UPDATING...", "AKTUALISIERE...", "ACTUALIZANDO..." },
            ["BtnError"]            = new[] { "ERREUR", "ERROR", "FEHLER", "ERROR" },
            ["LblController"]       = new[] { "CONTRÔLEUR", "CONTROLLER", "STEUERUNG", "CONTROLADOR" },
            ["LblEngine"]           = new[] { "MOTEUR", "ENGINE", "ENGINE", "MOTOR" },
            ["UpdateHint"]          = new[] { "Met à jour le contrôleur ET le moteur", "Updates the controller AND the engine", "Aktualisiert Steuerung UND Engine", "Actualiza el controlador Y el motor" },
            ["UpdateNone"]          = new[] { "Aucune mise à jour", "No update available", "Kein Update verfügbar", "Sin actualizaciones" },
            ["UpdateNew"]           = new[] { "Nouveau : {0}", "New: {0}", "Neu: {0}", "Nuevo: {0}" },
            ["UpdateChecking"]      = new[] { "Vérification...", "Checking...", "Prüfe...", "Comprobando..." },
            ["UpdateImpossible"]    = new[] { "Vérification impossible", "Check failed", "Prüfung fehlgeschlagen", "Comprobación fallida" },
            ["UpdateDisabled"]      = new[] { "Vérification désactivée", "Checking disabled", "Prüfung deaktiviert", "Comprobación desactivada" },
            ["TrayShow"]            = new[] { "Afficher le panneau", "Show panel", "Panel anzeigen", "Mostrar panel" },
            ["TraySettings"]        = new[] { "Réglages", "Settings", "Einstellungen", "Ajustes" },
            ["TrayQuit"]            = new[] { "Quitter", "Quit", "Beenden", "Salir" },
            ["TrayOnline"]          = new[] { "BirdNET-Go - En ligne", "BirdNET-Go - Online", "BirdNET-Go - Online", "BirdNET-Go - En línea" },
            ["TrayOffline"]         = new[] { "BirdNET-Go - Hors ligne", "BirdNET-Go - Offline", "BirdNET-Go - Offline", "BirdNET-Go - Sin conexión" },
            ["TrayTipText"]         = new[] { "L'app tourne en arrière-plan.", "The app is running in the background.", "Die App läuft im Hintergrund.", "La app sigue en segundo plano." },
            ["UpdateConfirmTitle"]  = new[] { "Mise à jour", "Update", "Aktualisierung", "Actualización" },
            ["UpdateConfirmText"]   = new[] { "L'application va se fermer pour installer la mise à jour (contrôleur + moteur). Continuer ?", "The app will close to install the update (controller + engine). Continue?", "Die App wird geschlossen, um das Update zu installieren (Steuerung + Engine). Fortfahren?", "La app se cerrará para instalar la actualización (controlador + motor). ¿Continuar?" },
            ["SettingsWindowTitle"] = new[] { "Réglages", "Settings", "Einstellungen", "Ajustes" },
            ["SettingsTitle"]       = new[] { "⚙️ Réglages du contrôleur", "⚙️ Controller settings", "⚙️ Steuerungseinstellungen", "⚙️ Ajustes del controlador" },
            ["SettingsIntro"]       = new[] { "Ces options concernent uniquement l'application de contrôle.", "These options apply to the controller app only.", "Diese Optionen betreffen nur die Steuerungs-App.", "Estas opciones afectan solo a la app de control." },
            ["GrpStartup"]          = new[] { "DÉMARRAGE", "STARTUP", "START", "INICIO" },
            ["ChkStartup"]          = new[] { "Lancer au démarrage de Windows", "Launch at Windows startup", "Mit Windows starten", "Iniciar con Windows" },
            ["ChkAutoStart"]        = new[] { "Démarrer le serveur auto à l'ouverture", "Start server automatically on launch", "Server beim Start automatisch starten", "Iniciar el servidor automáticamente" },
            ["ChkMinimize"]         = new[] { "Minimiser dans le tray au lancement", "Minimize to tray on launch", "Beim Start in den Tray minimieren", "Minimizar a la bandeja al iniciar" },
            ["GrpServer"]           = new[] { "SERVEUR (birdnet-go.exe)", "SERVER (birdnet-go.exe)", "SERVER (birdnet-go.exe)", "SERVIDOR (birdnet-go.exe)" },
            ["ChkAutoRestart"]      = new[] { "Relancer automatiquement en cas de crash", "Restart automatically after a crash", "Nach Absturz automatisch neu starten", "Reiniciar automáticamente tras un fallo" },
            ["LblAttempts"]         = new[] { "Tentatives max", "Max attempts", "Max. Versuche", "Intentos máx." },
            ["LblDelay"]            = new[] { "Délai avant relance", "Restart delay", "Wartezeit bis Neustart", "Retraso antes de reiniciar" },
            ["ChkStopOnExit"]       = new[] { "Arrêter le serveur en quittant l'app", "Stop server when quitting the app", "Server beim Beenden stoppen", "Detener el servidor al salir" },
            ["GrpUpdates"]          = new[] { "MISES À JOUR", "UPDATES", "UPDATES", "ACTUALIZACIONES" },
            ["LblFreq"]             = new[] { "Vérification", "Check every", "Prüfintervall", "Comprobar cada" },
            ["ChkNightly"]          = new[] { "Autoriser les versions Nightly (bêta)", "Allow Nightly (beta) versions", "Nightly-Versionen (Beta) erlauben", "Permitir versiones Nightly (beta)" },
            ["GrpUi"]               = new[] { "INTERFACE & MAINTENANCE", "INTERFACE & MAINTENANCE", "OBERFLÄCHE & WARTUNG", "INTERFAZ Y MANTENIMIENTO" },
            ["LblPort"]             = new[] { "Port de l'interface web", "Web interface port", "Port der Weboberfläche", "Puerto de la interfaz web" },
            ["LblPurge"]            = new[] { "Purge des logs", "Log cleanup", "Logs bereinigen", "Purga de registros" },
            ["ChkBalloon"]          = new[] { "Notifications (bulles tray)", "Notifications (tray balloons)", "Benachrichtigungen (Tray)", "Notificaciones (bandeja)" },
            ["GrpLanguage"]         = new[] { "LANGUE", "LANGUAGE", "SPRACHE", "IDIOMA" },
            ["LblLanguage"]         = new[] { "Langue de l'interface", "Interface language", "Sprache der Oberfläche", "Idioma de la interfaz" },
            ["LangAuto"]            = new[] { "Automatique (système)", "Automatic (system)", "Automatisch (System)", "Automático (sistema)" },
            ["GrpDetection"]        = new[] { "🐦 RÉGLAGES DE DÉTECTION", "🐦 DETECTION SETTINGS", "🐦 ERKENNUNGSEINSTELLUNGEN", "🐦 AJUSTES DE DETECCIÓN" },
            ["DetectionHint"]       = new[] { "Sensibilité, seuil de confiance, espèces… se configurent dans l'interface web du moteur, pas ici.", "Sensitivity, confidence threshold, species… are configured in the engine's web interface, not here.", "Empfindlichkeit, Schwellenwert, Arten… werden in der Weboberfläche der Engine eingestellt, nicht hier.", "Sensibilidad, umbral de confianza, especies… se configuran en la interfaz web del motor, no aquí." },
            ["BtnOpenEngineWeb"]    = new[] { "🌐 Ouvrir l'interface web du moteur", "🌐 Open the engine's web interface", "🌐 Weboberfläche der Engine öffnen", "🌐 Abrir la interfaz web del motor" },
            ["BtnCancel"]           = new[] { "Annuler", "Cancel", "Abbrechen", "Cancelar" },
            ["BtnSave"]             = new[] { "💾 Enregistrer", "💾 Save", "💾 Speichern", "💾 Guardar" },
            ["PortInvalid"]         = new[] { "Port invalide (1–65535).", "Invalid port (1–65535).", "Ungültiger Port (1–65535).", "Puerto no válido (1–65535)." },
            ["Never"]               = new[] { "Jamais", "Never", "Nie", "Nunca" },
            ["DaysShort"]           = new[] { "j", "d", "T", "d" },
        };
    }
}
