using System;
using System.Collections.Generic;
using System.Globalization;
using System.IO;
using System.Windows.Media;

namespace BirdNETGoControl
{
    public sealed class LangItem
    {
        public ImageSource Flag { get; init; }
        public string Native { get; init; } = "";
        public string English { get; init; } = "";
        public string Code { get; init; } = "";
    }

    public static class Loc
    {
        // Ordre BirdNET-Go (alphabétique sur le nom anglais) — l'ordre des colonnes du Map est IDENTIQUE
        public static readonly string[] Codes =
            { "cs", "da", "en", "de", "es", "fi", "fr", "hu", "it", "lv", "nb", "nl", "pl", "pt", "sk", "sv" };

        private static readonly int En = Array.IndexOf(Codes, "en");
        public static string Current { get; private set; } = "en";

        public static string NativeName(string c) => c switch
        {
            "cs" => "Čeština",        "da" => "Dansk",          "en" => "English",
            "de" => "Deutsch",        "es" => "Español",        "fi" => "Suomi",
            "fr" => "Français",       "hu" => "Magyar",         "it" => "Italiano",
            "lv" => "Latviešu",       "nb" => "Norsk bokmål",   "nl" => "Nederlands",
            "pl" => "Polski",         "pt" => "Português",      "sk" => "Slovenčina",
            "sv" => "Svenska",        _ => c
        };

        public static string EnglishName(string c) => c switch
        {
            "cs" => "Czech",          "da" => "Danish",         "en" => "English",
            "de" => "German",         "es" => "Spanish",        "fi" => "Finnish",
            "fr" => "French",         "hu" => "Hungarian",      "it" => "Italian",
            "lv" => "Latvian",        "nb" => "Norwegian",      "nl" => "Dutch",
            "pl" => "Polish",         "pt" => "Portuguese",     "sk" => "Slovak",
            "sv" => "Swedish",        _ => c
        };

        public static string DisplayName(string c) => NativeName(c);

        public static LangItem Item(string c) => new LangItem
        {
            Code = c,
            Native = NativeName(c),
            English = EnglishName(c),
            Flag = Flags.Get(c)
        };

        public static void Init(string pref)
        {
            if (string.IsNullOrWhiteSpace(pref) || pref == "auto")
            {
                string forced = "";
                try
                {
                    var f = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "LANGUAGE.txt");
                    if (File.Exists(f)) forced = File.ReadAllText(f).Trim().ToLowerInvariant();
                }
                catch { }

                string sys = CultureInfo.CurrentUICulture.TwoLetterISOLanguageName.ToLowerInvariant();
                if (sys == "no" || sys == "nn") sys = "nb";
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
            if (!Map.TryGetValue(key, out var v)) return key;
            int i = Array.IndexOf(Codes, Current);
            if (i < 0 || i >= v.Length) i = En;
            return string.IsNullOrEmpty(v[i]) ? v[En] : v[i];
        }

        //                              cs                     da                    en                     de                     es                     fi                     fr                     hu                     it                     lv                     nb                     nl                     pl                     pt                     sk                     sv
        private static readonly Dictionary<string, string[]> Map = new()
        {
            ["StatusOnline"]       = new[]{ "ONLINE", "ONLINE", "ONLINE", "ONLINE", "EN LÍNEA", "VERKOSSA", "EN LIGNE", "ONLINE", "ONLINE", "TIEŠSAISTĒ", "PÅLOGGET", "ONLINE", "ONLINE", "ONLINE", "ONLINE", "ONLINE" },
            ["StatusOffline"]      = new[]{ "OFFLINE", "OFFLINE", "OFFLINE", "OFFLINE", "SIN CONEXIÓN", "POISSA", "HORS LIGNE", "OFFLINE", "OFFLINE", "BEZSAISTĒ", "FRAKOBLET", "OFFLINE", "OFFLINE", "OFFLINE", "OFFLINE", "OFFLINE" },
            ["BtnStart"]           = new[]{ "SPUSTIT SERVER", "START SERVER", "START SERVER", "SERVER STARTEN", "INICIAR SERVIDOR", "KÄYNNISTÄ PALVELIN", "DÉMARRER LE SERVEUR", "SZERVER INDÍTÁSA", "AVVIA SERVER", "PALAIST SERVERI", "START SERVER", "SERVER STARTEN", "URUCHOM SERWER", "INICIAR SERVIDOR", "SPUSTIŤ SERVER", "STARTA SERVER" },
            ["BtnStop"]            = new[]{ "ZASTAVIT SERVER", "STOP SERVER", "STOP SERVER", "SERVER STOPPEN", "DETENER SERVIDOR", "PYSÄYTÄ PALVELIN", "ARRÊTER LE SERVEUR", "SZERVER LEÁLLÍTÁSA", "ARRESTA SERVER", "APTURĒT SERVERI", "STOPP SERVER", "SERVER STOPPEN", "ZATRZYMAJ SERWER", "PARAR SERVIDOR", "ZASTAVIŤ SERVER", "STOPPA SERVER" },
            ["BtnOpenWeb"]         = new[]{ "🌐 Otevřít webové rozhraní", "🌐 Åbn webgrænseflade", "🌐 Open web interface", "🌐 Weboberfläche öffnen", "🌐 Abrir interfaz web", "🌐 Avaa verkkokäyttöliittymä", "🌐 Ouvrir l'interface web", "🌐 Webes felület megnyitása", "🌐 Apri interfaccia web", "🌐 Atvērt tīmekļa saskarni", "🌐 Åpne nettgrensesnitt", "🌐 Webinterface openen", "🌐 Otwórz interfejs web", "🌐 Abrir interface web", "🌐 Otvoriť webové rozhranie", "🌐 Öppna webbgränssnitt" },
            ["BtnUpdate"]          = new[]{ "AKTUALIZOVAT", "OPDATER", "UPDATE", "AKTUALISIEREN", "ACTUALIZAR", "PÄIVITÄ", "METTRE À JOUR", "FRISSÍTÉS", "AGGIORNA", "ATJAUNINĀT", "OPPDATER", "BIJWERKEN", "AKTUALIZUJ", "ATUALIZAR", "AKTUALIZOVAŤ", "UPPDATERA" },
            ["BtnUpdateAvailable"] = new[]{ "AKTUALIZACE K DISPOZICI", "OPDATERING TILGÆNGELIG", "UPDATE AVAILABLE", "UPDATE VERFÜGBAR", "ACTUALIZACIÓN DISPONIBLE", "PÄIVITYS SAATAVILLA", "MAJ DISPONIBLE", "FRISSÍTÉS ÉRHETŐ EL", "AGGIORNAMENTO DISPONIBILE", "ATJAUNINĀJUMS PIEEJAMS", "OPPDATERING TILGJENGELIG", "UPDATE BESCHIKBAAR", "AKTUALIZACJA DOSTĘPNA", "ATUALIZAÇÃO DISPONÍVEL", "AKTUALIZÁCIA K DISPOZÍCII", "UPPDATERING TILLGÄNGLIG" },
            ["BtnUpdating"]        = new[]{ "AKTUALIZACE...", "OPDATERER...", "UPDATING...", "AKTUALISIERE...", "ACTUALIZANDO...", "PÄIVITETÄÄN...", "MISE À JOUR...", "FRISSÍTÉS...", "AGGIORNAMENTO...", "ATJAUNINA...", "OPPDATERER...", "BIJWERKEN...", "AKTUALIZACJA...", "ATUALIZANDO...", "AKTUALIZÁCIA...", "UPPDATERAR..." },
            ["BtnError"]           = new[]{ "CHYBA", "FEJL", "ERROR", "FEHLER", "ERROR", "VIRHE", "ERREUR", "HIBA", "ERRORE", "KĻŪDA", "FEIL", "FOUT", "BŁĄD", "ERRO", "CHYBA", "FEL" },
            ["LblController"]      = new[]{ "OVLADAČ", "STYRING", "CONTROLLER", "STEUERUNG", "CONTROLADOR", "OHJAIN", "CONTRÔLEUR", "VEZÉRLŐ", "CONTROLLORE", "VADĪTĀJS", "KONTROLLER", "CONTROLLER", "KONTROLER", "CONTROLADOR", "OVLÁDAČ", "KONTROLLER" },
            ["LblEngine"]          = new[]{ "JÁDRO", "MOTOR", "ENGINE", "ENGINE", "MOTOR", "MOOTTORI", "MOTEUR", "MOTOR", "MOTORE", "DZINĒJS", "MOTOR", "ENGINE", "SILNIK", "MOTOR", "JADRO", "MOTOR" },
            ["UpdateHint"]         = new[]{ "Ovladač + jádro", "Styring + motor", "Controller + engine", "Steuerung + Engine", "Controlador + motor", "Ohjain + moottori", "Contrôleur + moteur", "Vezérlő + motor", "Controllore + motore", "Vadītājs + dzinējs", "Kontroller + motor", "Controller + engine", "Kontroler + silnik", "Controlador + motor", "Ovládač + jadro", "Kontroller + motor" },
            ["UpdateNone"]         = new[]{ "Žádná aktualizace", "Ingen opdatering", "No update available", "Kein Update verfügbar", "Sin actualizaciones", "Ei päivityksiä", "Aucune mise à jour", "Nincs frissítés", "Nessun aggiornamento", "Nav atjauninājumu", "Ingen oppdatering", "Geen update", "Brak aktualizacji", "Sem atualizações", "Žiadna aktualizácia", "Ingen uppdatering" },
            ["UpdateNew"]          = new[]{ "Nová: {0}", "Ny: {0}", "New: {0}", "Neu: {0}", "Nueva: {0}", "Uusi: {0}", "Nouveau : {0}", "Új: {0}", "Nuova: {0}", "Jauna: {0}", "Ny: {0}", "Nieuw: {0}", "Nowa: {0}", "Nova: {0}", "Nová: {0}", "Ny: {0}" },
            ["UpdateImpossible"]   = new[]{ "Kontrola selhala", "Tjek mislykkedes", "Check failed", "Prüfung fehlgeschlagen", "Comprobación fallida", "Tarkistus epäonnistui", "Vérification impossible", "Ellenőrzés sikertelen", "Verifica non riuscita", "Pārbaude neizdevās", "Sjekk mislyktes", "Controle mislukt", "Sprawdzanie nieudane", "Verificação falhou", "Kontrola zlyhala", "Kontroll misslyckades" },
            ["UpdateDisabled"]     = new[]{ "Kontrola vypnuta", "Tjek deaktiveret", "Checking disabled", "Prüfung deaktiviert", "Comprobación desactivada", "Tarkistus pois käytöstä", "Vérification désactivée", "Ellenőrzés kikapcsolva", "Verifica disattivata", "Pārbaude atspējota", "Sjekk deaktivert", "Controle uitgeschakeld", "Sprawdzanie wyłączone", "Verificação desativada", "Kontrola vypnutá", "Kontroll avaktiverad" },
            ["TrayShow"]           = new[]{ "Zobrazit panel", "Vis panel", "Show panel", "Panel anzeigen", "Mostrar panel", "Näytä paneeli", "Afficher le panneau", "Panel megjelenítése", "Mostra pannello", "Rādīt paneli", "Vis panel", "Paneel tonen", "Pokaż panel", "Mostrar painel", "Zobraziť panel", "Visa panel" },
            ["TraySettings"]       = new[]{ "Nastavení", "Indstillinger", "Settings", "Einstellungen", "Ajustes", "Asetukset", "Réglages", "Beállítások", "Impostazioni", "Iestatījumi", "Innstillinger", "Instellingen", "Ustawienia", "Configurações", "Nastavenia", "Inställningar" },
            ["TrayQuit"]           = new[]{ "Ukončit", "Afslut", "Quit", "Beenden", "Salir", "Lopeta", "Quitter", "Kilépés", "Esci", "Iziet", "Avslutt", "Afsluiten", "Zakończ", "Sair", "Ukončiť", "Avsluta" },
            ["TrayOnline"]         = new[]{ "BirdNET-Go – online", "BirdNET-Go – online", "BirdNET-Go – Online", "BirdNET-Go – online", "BirdNET-Go – en línea", "BirdNET-Go – verkossa", "BirdNET-Go – en ligne", "BirdNET-Go – online", "BirdNET-Go – online", "BirdNET-Go – tiešsaistē", "BirdNET-Go – pålogget", "BirdNET-Go – online", "BirdNET-Go – online", "BirdNET-Go – online", "BirdNET-Go – online", "BirdNET-Go – online" },
            ["TrayOffline"]        = new[]{ "BirdNET-Go – offline", "BirdNET-Go – offline", "BirdNET-Go – Offline", "BirdNET-Go – offline", "BirdNET-Go – sin conexión", "BirdNET-Go – poissa", "BirdNET-Go – hors ligne", "BirdNET-Go – offline", "BirdNET-Go – offline", "BirdNET-Go – bezsaistē", "BirdNET-Go – frakoblet", "BirdNET-Go – offline", "BirdNET-Go – offline", "BirdNET-Go – offline", "BirdNET-Go – offline", "BirdNET-Go – offline" },
            ["TrayTipText"]        = new[]{ "Aplikace běží na pozadí.", "Appen kører i baggrunden.", "The app is running in the background.", "Die App läuft im Hintergrund.", "La app sigue en segundo plano.", "Sovellus toimii taustalla.", "L'app tourne en arrière-plan.", "Az alkalmazás a háttérben fut.", "L'app è in esecuzione in background.", "Lietotne darbojas fonā.", "Appen kjører i bakgrunnen.", "De app draait op de achtergrond.", "Aplikacja działa w tle.", "O app continua em segundo plano.", "Aplikácia beží na pozadí.", "Appen körs i bakgrunden." },
            ["UpdateConfirmTitle"] = new[]{ "Aktualizace", "Opdatering", "Update", "Aktualisierung", "Actualización", "Päivitys", "Mise à jour", "Frissítés", "Aggiornamento", "Atjaunināšana", "Oppdatering", "Update", "Aktualizacja", "Atualização", "Aktualizácia", "Uppdatering" },
            ["UpdateConfirmText"]  = new[]{ "Zavřít aplikaci a nainstalovat aktualizaci (ovladač + jádro)?", "Luk appen og installer opdateringen (styring + motor)?", "Close the app and install the update (controller + engine)?", "App schließen und Update installieren (Steuerung + Engine)?", "¿Cerrar la app e instalar la actualización (controlador + motor)?", "Suljetaanko sovellus ja asennetaan päivitys (ohjain + moottori)?", "Fermer l'app et installer la mise à jour (contrôleur + moteur) ?", "Bezárja az alkalmazást és telepíti a frissítést (vezérlő + motor)?", "Chiudere l'app e installare l'aggiornamento (controllore + motore)?", "Aizvērt lietotni un instalēt atjauninājumu (vadītājs + dzinējs)?", "Lukke appen og installere oppdateringen (kontroller + motor)?", "App sluiten en update installeren (controller + engine)?", "Zamknąć aplikację i zainstalować aktualizację (kontroler + silnik)?", "Fechar o app e instalar a atualização (controlador + motor)?", "Zavrieť aplikáciu a nainštalovať aktualizáciu (ovládač + jadro)?", "Stänga appen och installera uppdateringen (kontroller + motor)?" },
            ["SettingsWindowTitle"]= new[]{ "Nastavení", "Indstillinger", "Settings", "Einstellungen", "Ajustes", "Asetukset", "Réglages", "Beállítások", "Impostazioni", "Iestatījumi", "Innstillinger", "Instellingen", "Ustawienia", "Configurações", "Nastavenia", "Inställningar" },
            ["SettingsTitle"]      = new[]{ "⚙️ Nastavení ovladače", "⚙️ Styringsindstillinger", "⚙️ Controller settings", "⚙️ Steuerungseinstellungen", "⚙️ Ajustes del controlador", "⚙️ Ohjaimen asetukset", "⚙️ Réglages du contrôleur", "⚙️ Vezérlő beállításai", "⚙️ Impostazioni controllore", "⚙️ Vadītāja iestatījumi", "⚙️ Kontrollerinnstillinger", "⚙️ Controllerinstellingen", "⚙️ Ustawienia kontrolera", "⚙️ Configurações do controlador", "⚙️ Nastavenia ovládača", "⚙️ Kontrollerinställningar" },
            ["SettingsIntro"]      = new[]{ "Pouze možnosti ovladače.", "Kun styringsindstillinger.", "Controller app options only.", "Nur Optionen der Steuerung.", "Solo opciones del controlador.", "Vain ohjaimen asetukset.", "Options du contrôleur uniquement.", "Csak a vezérlő beállításai.", "Solo opzioni del controllore.", "Tikai vadītāja opcijas.", "Kun kontrollerinnstillinger.", "Alleen controller-opties.", "Tylko opcje kontrolera.", "Apenas opções do controlador.", "Iba možnosti ovládača.", "Endast kontrolleralternativ." },
            ["GrpStartup"]         = new[]{ "SPUŠTĚNÍ", "OPSTART", "STARTUP", "START", "INICIO", "KÄYNNISTYS", "DÉMARRAGE", "INDÍTÁS", "AVVIO", "PALAIŠANA", "OPPSTART", "OPSTARTEN", "URUCHAMIANIE", "INICIALIZAÇÃO", "SPUSTENIE", "START" },
            ["ChkStartup"]         = new[]{ "Spustit při startu Windows", "Start sammen med Windows", "Launch at Windows startup", "Mit Windows starten", "Iniciar con Windows", "Käynnistä Windowsin mukana", "Lancer au démarrage de Windows", "Indítás a Windows-zal", "Avvia con Windows", "Palaist līdz ar Windows", "Start med Windows", "Starten met Windows", "Uruchamiaj z Windows", "Iniciar com o Windows", "Spustiť pri štarte Windows", "Starta med Windows" },
            ["ChkAutoStart"]       = new[]{ "Automaticky spustit server", "Start serveren automatisk", "Start server automatically", "Server automatisch starten", "Iniciar el servidor automáticamente", "Käynnistä palvelin automaattisesti", "Démarrer le serveur automatiquement", "Szerver automatikus indítása", "Avvia il server automaticamente", "Automātiski palaist serveri", "Start serveren automatisk", "Server automatisch starten", "Automatycznie uruchamiaj serwer", "Iniciar o servidor automaticamente", "Automaticky spustiť server", "Starta servern automatiskt" },
            ["ChkMinimize"]        = new[]{ "Minimalizovat do lišty", "Minimer til systembakken", "Minimize to tray on launch", "Beim Start in den Tray", "Minimizar a la bandeja", "Pienennä ilmaisinalueelle", "Minimiser dans le tray", "Kis méret a tálcán", "Riduci a icona nell'area notifiche", "Minimizēt teknē", "Minimer til systemkurven", "Minimaliseren naar systeemvak", "Minimalizuj do zasobnika", "Minimizar para a bandeja", "Minimalizovať do oblasti oznámení", "Minimera till systemfältet" },
            ["GrpServer"]          = new[]{ "SERVER (birdnet-go.exe)", "SERVER (birdnet-go.exe)", "SERVER (birdnet-go.exe)", "SERVER (birdnet-go.exe)", "SERVIDOR (birdnet-go.exe)", "PALVELIN (birdnet-go.exe)", "SERVEUR (birdnet-go.exe)", "SZERVER (birdnet-go.exe)", "SERVER (birdnet-go.exe)", "SERVERIS (birdnet-go.exe)", "SERVER (birdnet-go.exe)", "SERVER (birdnet-go.exe)", "SERWER (birdnet-go.exe)", "SERVIDOR (birdnet-go.exe)", "SERVER (birdnet-go.exe)", "SERVER (birdnet-go.exe)" },
            ["ChkAutoRestart"]     = new[]{ "Po pádu znovu spustit", "Genstart efter nedbrud", "Restart after a crash", "Nach Absturz neu starten", "Reiniciar tras un fallo", "Käynnistä uudelleen kaatumisen jälkeen", "Relancer après un crash", "Újraindítás összeomlás után", "Riavvia dopo un arresto anomalo", "Pārstartēt pēc avārijas", "Start på nytt etter krasj", "Herstarten na een crash", "Restart po awarii", "Reiniciar após uma falha", "Po zlyhaní reštartovať", "Starta om efter krasch" },
            ["LblAttempts"]        = new[]{ "Max. pokusů", "Maks. forsøg", "Max attempts", "Max. Versuche", "Intentos máx.", "Enimmäisyritykset", "Tentatives max", "Max. próbálkozás", "Tentativi max", "Maks. mēģinājumi", "Maks. forsøk", "Max. pogingen", "Maks. prób", "Máx. tentativas", "Max. pokusov", "Max. försök" },
            ["LblDelay"]           = new[]{ "Prodleva restartu", "Genstartforsinkelse", "Restart delay", "Wartezeit bis Neustart", "Retraso de reinicio", "Uudelleenkäynnistyksen viive", "Délai avant relance", "Újraindítási késleltetés", "Ritardo riavvio", "Pārstartēšanas aizkave", "Omstartsforsinkelse", "Herstartvertraging", "Opóźnienie restartu", "Atraso de reinício", "Oneskorenie reštartu", "Omstartsfördröjning" },
            ["ChkStopOnExit"]      = new[]{ "Zastavit server při ukončení", "Stop serveren ved afslutning", "Stop server when quitting", "Server beim Beenden stoppen", "Detener el servidor al salir", "Pysäytä palvelin lopetettaessa", "Arrêter le serveur en quittant", "Szerver leállítása kilépéskor", "Arresta il server all'uscita", "Apturēt serveri, iz ejot", "Stopp serveren ved avslutning", "Server stoppen bij afsluiten", "Zatrzymaj serwer przy wyjściu", "Parar o servidor ao sair", "Zastaviť server pri ukončení", "Stoppa servern vid avslut" },
            ["GrpUpdates"]         = new[]{ "AKTUALIZACE", "OPDATERINGER", "UPDATES", "UPDATES", "ACTUALIZACIONES", "PÄIVITYKSET", "MISES À JOUR", "FRISSÍTÉSEK", "AGGIORNAMENTI", "ATJAUNINĀJUMI", "OPPDATERINGER", "UPDATES", "AKTUALIZACJE", "ATUALIZAÇÕES", "AKTUALIZÁCIE", "UPPDATERINGAR" },
            ["LblFreq"]            = new[]{ "Kontrolovat každých", "Tjek hver", "Check every", "Prüfintervall", "Comprobar cada", "Tarkista joka", "Vérification", "Ellenőrzés gyakorisága", "Verifica ogni", "Pārbaudīt ik pēc", "Sjekk hver", "Controleren elke", "Sprawdzaj co", "Verificar a cada", "Kontrolovať každých", "Kontrollera var" },
            ["ChkNightly"]         = new[]{ "Povolit Nightly (beta)", "Tillad Nightly (beta)", "Allow Nightly (beta)", "Nightly (Beta) erlauben", "Permitir Nightly (beta)", "Salli Nightly (beta)", "Autoriser les Nightly (bêta)", "Nightly (béta) engedélyezése", "Consenti Nightly (beta)", "Atļaut Nightly (beta)", "Tillat Nightly (beta)", "Nightly (bèta) toestaan", "Zezwalaj na Nightly (beta)", "Permitir Nightly (beta)", "Povoliť Nightly (beta)", "Tillåt Nightly (beta)" },
            ["GrpUi"]              = new[]{ "ROZHRANÍ A ÚDRŽBA", "GRÆNSEFLADE & VEDLIGEHOLD", "INTERFACE & MAINTENANCE", "OBERFLÄCHE & WARTUNG", "INTERFAZ Y MANTENIMIENTO", "KÄYTTÖLIITTYMÄ & YLLÄPITO", "INTERFACE & MAINTENANCE", "FELÜLET & KARBANTARTÁS", "INTERFACCIA & MANUTENZIONE", "SASKARNE & APKOPE", "GRENSESNITT & VEDLIKEHOLD", "INTERFACE & ONDERHOUD", "INTERFEJS I KONSERWACJA", "INTERFACE & MANUTENÇÃO", "ROZHRANIE A ÚDRŽBA", "GRÄNSSNITT & UNDERHÅLL" },
            ["LblPort"]            = new[]{ "Port webového rozhraní", "Webgrænsefladens port", "Web interface port", "Port der Weboberfläche", "Puerto de la interfaz web", "Verkkokäyttöliittymän portti", "Port de l'interface web", "Webes felület portja", "Porta interfaccia web", "Tīmekļa saskarnes ports", "Nettgrensesnittport", "Poort webinterface", "Port interfejsu web", "Porta da interface web", "Port webového rozhrania", "Webbgränssnittets port" },
            ["LblPurge"]           = new[]{ "Čištění protokolů", "Ryd op i logfiler", "Log cleanup", "Logs bereinigen", "Purga de registros", "Lokien puhdistus", "Purge des logs", "Naplók tisztítása", "Pulizia registri", "Žurnālu tīrīšana", "Loggopprydding", "Logboeken opschonen", "Czyszczenie dzienników", "Limpeza de registos", "Čistenie denníkov", "Loggrensning" },
            ["ChkBalloon"]         = new[]{ "Oznámení v liště", "Meddelelser i systembakken", "Tray notifications", "Tray-Benachrichtigungen", "Notificaciones de bandeja", "Ilmaisinalueen ilmoitukset", "Notifications (bulles tray)", "Tálcaértesítések", "Notifiche area notifiche", "Paziņojumi teknē", "Systemkurvvarsler", "Systeemvakmeldingen", "Powiadomienia w zasobniku", "Notificações da bandeja", "Oznámenia v oblasti oznámení", "Systemfältsaviseringar" },
            ["GrpLanguage"]        = new[]{ "JAZYK", "SPROG", "LANGUAGE", "SPRACHE", "IDIOMA", "KIELI", "LANGUE", "NYELV", "LINGUA", "VALODA", "SPRÅK", "TAAL", "JĘZYK", "IDIOMA", "JAZYK", "SPRÅK" },
            ["LblLanguage"]        = new[]{ "Jazyk rozhraní", "Grænsefladens sprog", "Interface language", "Sprache der Oberfläche", "Idioma de la interfaz", "Käyttöliittymän kieli", "Langue de l'interface", "Felület nyelve", "Lingua dell'interfaccia", "Saskarnes valoda", "Grensesnittspråk", "Interfacetaal", "Język interfejsu", "Idioma da interface", "Jazyk rozhrania", "Gränssnittsspråk" },
            ["LangAuto"]           = new[]{ "Automaticky (systém)", "Automatisk (system)", "Automatic (system)", "Automatisch (System)", "Automático (sistema)", "Automaattinen (järjestelmä)", "Automatique (système)", "Automatikus (rendszer)", "Automatico (sistema)", "Automātiski (sistēma)", "Automatisk (system)", "Automatisch (systeem)", "Automatycznie (system)", "Automático (sistema)", "Automaticky (systém)", "Automatiskt (system)" },
            ["GrpDetection"]       = new[]{ "🐦 NASTAVENÍ DETEKCE", "🐦 DETEKTIONSINDSTILLINGER", "🐦 DETECTION SETTINGS", "🐦 ERKENNUNGSEINSTELLUNGEN", "🐦 AJUSTES DE DETECCIÓN", "🐦 TUNNISTUSASETUKSET", "🐦 RÉGLAGES DE DÉTECTION", "🐦 ÉSZLELÉSI BEÁLLÍTÁSOK", "🐦 IMPOSTAZIONI RILEVAMENTO", "🐦 NOTEIKŠANAS IESTATĪJUMI", "🐦 DETEKSJONSINNSTILLINGER", "🐦 DETECTIE-INSTELLINGEN", "🐦 USTAWIENIA WYKRYWANIA", "🐦 CONFIGURAÇÕES DE DETEÇÃO", "🐦 NASTAVENIA DETEKCI", "🐦 DETEKTERINGSINSTÄLLNINGAR" },
            ["DetectionHint"]      = new[]{ "Citlivost, práh a druhy: ve webovém rozhraní jádra.", "Følsomhed, tærskel og arter: i motorens webgrænseflade.", "Sensitivity, threshold and species: in the engine's web interface.", "Empfindlichkeit, Schwellenwert, Arten: in der Weboberfläche der Engine.", "Sensibilidad, umbral y especies: en la interfaz web del motor.", "Herkkyys, kynnys ja lajit: moottorin verkkokäyttöliittymässä.", "Sensibilité, seuil, espèces : dans l'interface web du moteur.", "Érzékenység, küszöb, fajok: a motor webes felületén.", "Sensibilità, soglia e specie: nell'interfaccia web del motore.", "Jutība, slieksnis un sugas: dzinēja tīmekļa saskarnē.", "Følsomhet, terskel og arter: i motorens nettgrensesnitt.", "Gevoeligheid, drempel en soorten: in de webinterface van de engine.", "Czułość, próg i gatunki: w interfejsie web silnika.", "Sensibilidade, limiar e espécies: na interface web do motor.", "Citlivosť, prah a druhy: vo webovom rozhraní jadra.", "Känslighet, tröskel och arter: i motorns webbgränssnitt." },
            ["BtnOpenEngineWeb"]   = new[]{ "🌐 Otevřít rozhraní jádra", "🌐 Åbn motorens webgrænseflade", "🌐 Open the engine's web interface", "🌐 Weboberfläche der Engine öffnen", "🌐 Abrir la interfaz web del motor", "🌐 Avaa moottorin verkkokäyttöliittymä", "🌐 Ouvrir l'interface web du moteur", "🌐 A motor webes felületének megnyitása", "🌐 Apri l'interfaccia web del motore", "🌐 Atvērt dzinēja tīmekļa saskarni", "🌐 Åpne motorens nettgrensesnitt", "🌐 Webinterface van de engine openen", "🌐 Otwórz interfejs web silnika", "🌐 Abrir a interface web do motor", "🌐 Otvoriť webové rozhranie jadra", "🌐 Öppna motorns webbgränssnitt" },
            ["BtnCancel"]          = new[]{ "Zrušit", "Annuller", "Cancel", "Abbrechen", "Cancelar", "Peruuta", "Annuler", "Mégse", "Annulla", "Atcelt", "Avbryt", "Annuleren", "Anuluj", "Cancelar", "Zrušiť", "Avbryt" },
            ["BtnSave"]            = new[]{ "💾 Uložit", "💾 Gem", "💾 Save", "💾 Speichern", "💾 Guardar", "💾 Tallenna", "💾 Enregistrer", "💾 Mentés", "💾 Salva", "💾 Saglabāt", "💾 Lagre", "💾 Opslaan", "💾 Zapisz", "💾 Guardar", "💾 Uložiť", "💾 Spara" },
            ["PortInvalid"]        = new[]{ "Neplatný port (1–65535).", "Ugyldig port (1–65535).", "Invalid port (1–65535).", "Ungültiger Port (1–65535).", "Puerto no válido (1–65535).", "Virheellinen portti (1–65535).", "Port invalide (1–65535).", "Érvénytelen port (1–65535).", "Porta non valida (1–65535).", "Nederīgs ports (1–65535).", "Ugyldig port (1–65535).", "Ongeldige poort (1–65535).", "Nieprawidłowy port (1–65535).", "Porta inválida (1–65535).", "Neplatný port (1–65535).", "Ogiltig port (1–65535)." },
            ["Never"]              = new[]{ "Nikdy", "Aldrig", "Never", "Nie", "Nunca", "Ei koskaan", "Jamais", "Soha", "Mai", "Nekad", "Aldri", "Nooit", "Nigdy", "Nunca", "Nikdy", "Aldrig" },
            ["DaysShort"]          = new[]{ "d", "d", "d", "T", "d", "pv", "j", "n", "g", "d", "d", "d", "d", "d", "d", "d" },
        };
    }
}
