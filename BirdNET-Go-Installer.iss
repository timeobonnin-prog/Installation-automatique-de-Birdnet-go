; ---------------------------------------------------------------
;  BirdNET-Go — Installateur Windows (Inno Setup 6) — USER SCOPE
;  16 langues BirdNET-Go + LANGUAGE.txt transmis à l'application
; ---------------------------------------------------------------

#define MyAppName "BirdNET-Go"
#define MyAppExeName "BirdNET-Go-Control.exe"
#define MyAppPublisher "timeobonnin-prog"
#define MyAppURL "https://github.com/timeobonnin-prog/Installation-automatique-de-Birdnet-go"

[Setup]
AppId=BirdNETGo
AppName={#MyAppName}
AppVersion=1.0
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}/releases

PrivilegesRequired=lowest
PrivilegesRequiredOverridesAllowed=commandline
DefaultDirName={localappdata}\Programs\BirdNET-Go
DefaultGroupName={#MyAppName}
DisableProgramGroupPage=yes
UninstallDisplayName={#MyAppName}
UninstallDisplayIcon={app}\{#MyAppExeName}
OutputDir=Output
OutputBaseFilename=BirdNET-Go-Windows
SetupIconFile=icon.ico
Compression=lzma2/ultra64
SolidCompression=yes
WizardStyle=modern
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
VersionInfoVersion=1.0.0.0
VersionInfoCompany={#MyAppPublisher}
VersionInfoProductName={#MyAppName}
VersionInfoDescription=Installateur {#MyAppName}
ShowLanguageDialog=yes

AppMutex=BirdNETGoControl_SingleInstance_Mutex
CloseApplications=yes
RestartApplications=no

[Languages]
Name: "cs"; MessagesFile: "compiler:Languages\Czech.isl"
Name: "da"; MessagesFile: "compiler:Languages\Danish.isl"
Name: "en"; MessagesFile: "compiler:Default.isl"
Name: "de"; MessagesFile: "compiler:Languages\German.isl"
Name: "es"; MessagesFile: "compiler:Languages\Spanish.isl"
Name: "fi"; MessagesFile: "compiler:Languages\Finnish.isl"
Name: "fr"; MessagesFile: "compiler:Languages\French.isl"
Name: "hu"; MessagesFile: "compiler:Languages\Hungarian.isl"
Name: "it"; MessagesFile: "compiler:Languages\Italian.isl"
; Latvian : pas de .isl officiel Inno -> chrome anglais, messages perso en letton
Name: "lv"; MessagesFile: "compiler:Default.isl"
Name: "nb"; MessagesFile: "compiler:Languages\Norwegian.isl"
Name: "nl"; MessagesFile: "compiler:Languages\Dutch.isl"
Name: "pl"; MessagesFile: "compiler:Languages\Polish.isl"
Name: "pt"; MessagesFile: "compiler:Languages\Portuguese.isl"
Name: "sk"; MessagesFile: "compiler:Languages\Slovak.isl"
Name: "sv"; MessagesFile: "compiler:Languages\Swedish.isl"

[CustomMessages]
cs.TaskDesktop=Vytvořit zástupce na ploše
da.TaskDesktop=Opret genvej på skrivebordet
en.TaskDesktop=Create a desktop shortcut
de.TaskDesktop=Desktop-Verknüpfung erstellen
es.TaskDesktop=Crear acceso directo en el escritorio
fi.TaskDesktop=Luo työpöydän pikakuvake
fr.TaskDesktop=Créer un raccourci sur le Bureau
hu.TaskDesktop=Asztali parancsikon létrehozása
it.TaskDesktop=Crea collegamento sul desktop
lv.TaskDesktop=Izveidot saīsni darbvirsmā
nb.TaskDesktop=Opprett snarvei på skrivebordet
nl.TaskDesktop=Snelkoppeling op bureaublad maken
pl.TaskDesktop=Utwórz skrót na pulpicie
pt.TaskDesktop=Criar atalho no ambiente de trabalho
sk.TaskDesktop=Vytvoriť odkaz na pracovnej ploche
sv.TaskDesktop=Skapa genväg på skrivbordet

cs.TaskFirewall=Povolit přístup ze sítě (LAN) na portu 8080 - vyžaduje práva správce
da.TaskFirewall=Tillad netværksadgang (LAN) på port 8080 - kræver administratorrettigheder
en.TaskFirewall=Allow network (LAN) access on port 8080 - requires administrator rights
de.TaskFirewall=Netzwerkzugriff (LAN) auf Port 8080 erlauben - erfordert Administratorrechte
es.TaskFirewall=Permitir acceso de red (LAN) al puerto 8080 - requiere derechos de administrador
fi.TaskFirewall=Salli verkkoyhteys (LAN) portissa 8080 - vaatii järjestelmänvalvojan oikeudet
fr.TaskFirewall=Autoriser l'accès réseau (LAN) au port 8080 - demande les droits administrateur
hu.TaskFirewall=Hálózati (LAN) hozzáférés engedélyezése a 8080-as porton - rendszergazdai jog kell
it.TaskFirewall=Consenti accesso di rete (LAN) sulla porta 8080 - richiede diritti di amministratore
lv.TaskFirewall=Atļaut tīkla (LAN) piekļuvi portam 8080 - nepieciešamas administratora tiesības
nb.TaskFirewall=Tillat nettverkstilgang (LAN) på port 8080 - krever administratorrettigheter
nl.TaskFirewall=Netwerktoegang (LAN) op poort 8080 toestaan - vereist beheerdersrechten
pl.TaskFirewall=Zezwól na dostęp sieciowy (LAN) na porcie 8080 - wymaga uprawnień administratora
pt.TaskFirewall=Permitir acesso de rede (LAN) na porta 8080 - requer direitos de administrador
sk.TaskFirewall=Povoliť sieťový prístup (LAN) na porte 8080 - vyžaduje práva správcu
sv.TaskFirewall=Tillåt nätverksåtkomst (LAN) på port 8080 - kräver administratörsrättigheter

cs.GroupShortcuts=Zástupci:
da.GroupShortcuts=Genveje:
en.GroupShortcuts=Shortcuts:
de.GroupShortcuts=Verknüpfungen:
es.GroupShortcuts=Accesos directos:
fi.GroupShortcuts=Pikakuvakkeet:
fr.GroupShortcuts=Raccourcis :
hu.GroupShortcuts=Parancsikonok:
it.GroupShortcuts=Collegamenti:
lv.GroupShortcuts=Saīsnes:
nb.GroupShortcuts=Snarveier:
nl.GroupShortcuts=Snelkoppelingen:
pl.GroupShortcuts=Skróty:
pt.GroupShortcuts=Atalhos:
sk.GroupShortcuts=Odkazy:
sv.GroupShortcuts=Genvägar:

cs.GroupNetwork=Síť:
da.GroupNetwork=Netværk:
en.GroupNetwork=Network:
de.GroupNetwork=Netzwerk:
es.GroupNetwork=Red:
fi.GroupNetwork=Verkko:
fr.GroupNetwork=Réseau :
hu.GroupNetwork=Hálózat:
it.GroupNetwork=Rete:
lv.GroupNetwork=Tīkls:
nb.GroupNetwork=Nettverk:
nl.GroupNetwork=Netwerk:
pl.GroupNetwork=Sieć:
pt.GroupNetwork=Rede:
sk.GroupNetwork=Sieť:
sv.GroupNetwork=Nätverk:

cs.LaunchApp=Spustit BirdNET-Go
da.LaunchApp=Start BirdNET-Go
en.LaunchApp=Launch BirdNET-Go
de.LaunchApp=BirdNET-Go starten
es.LaunchApp=Iniciar BirdNET-Go
fi.LaunchApp=Käynnistä BirdNET-Go
fr.LaunchApp=Lancer BirdNET-Go
hu.LaunchApp=BirdNET-Go indítása
it.LaunchApp=Avvia BirdNET-Go
lv.LaunchApp=Palaist BirdNET-Go
nb.LaunchApp=Start BirdNET-Go
nl.LaunchApp=BirdNET-Go starten
pl.LaunchApp=Uruchom BirdNET-Go
pt.LaunchApp=Iniciar BirdNET-Go
sk.LaunchApp=Spustiť BirdNET-Go
sv.LaunchApp=Starta BirdNET-Go

cs.RemoveFirewall=Odstranit pravidlo brány firewall "%1"?
da.RemoveFirewall=Fjern firewallreglen "%1"?
en.RemoveFirewall=Remove the firewall rule "%1"?
de.RemoveFirewall=Firewall-Regel "%1" entfernen?
es.RemoveFirewall=¿Eliminar la regla de firewall "%1"?
fi.RemoveFirewall=Poistetaanko palomuurisääntö "%1"?
fr.RemoveFirewall=Supprimer la règle de pare-feu "%1" ?
hu.RemoveFirewall=Eltávolítja a "%1" tűzfalszabályt?
it.RemoveFirewall=Rimuovere la regola firewall "%1"?
lv.RemoveFirewall=Noņemt ugunsmūra kārtulu "%1"?
nb.RemoveFirewall=Fjerne brannmurregelen "%1"?
nl.RemoveFirewall=Firewallregel "%1" verwijderen?
pl.RemoveFirewall=Usunąć regułę zapory "%1"?
pt.RemoveFirewall=Remover a regra de firewall "%1"?
sk.RemoveFirewall=Odstrániť pravidlo firewallu "%1"?
sv.RemoveFirewall=Ta bort brandväggsregeln "%1"?

[Tasks]
Name: "desktopicon"; Description: "{cm:TaskDesktop}"; GroupDescription: "{cm:GroupShortcuts}"; Flags: unchecked
Name: "firewall"; Description: "{cm:TaskFirewall}"; GroupDescription: "{cm:GroupNetwork}"; Flags: unchecked; Check: not WizardSilent

[Files]
Source: "dist\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "icon.ico"; DestDir: "{app}"; Flags: ignoreversion
Source: "start_birdnet.bat"; DestDir: "{app}"; Flags: ignoreversion skipifsourcedoesntexist

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; IconFilename: "{app}\icon.ico"
Name: "{group}\{cm:UninstallProgram,{#MyAppName}}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; IconFilename: "{app}\icon.ico"; Tasks: desktopicon

[Registry]
Root: HKCU; Subkey: "Software\Microsoft\Windows\CurrentVersion\Run"; ValueType: none; ValueName: "BirdNETGoControl"; Flags: uninsdeletevalue

[UninstallRun]
Filename: "{cmd}"; Parameters: "/C taskkill /F /IM birdnet-go.exe"; Flags: runhidden; RunOnceId: "KillBirdnetServer"
Filename: "{cmd}"; Parameters: "/C taskkill /F /IM {#MyAppExeName}"; Flags: runhidden; RunOnceId: "KillBirdnetControl"

[UninstallDelete]
Type: filesandordirs; Name: "{userappdata}\BirdNETGoControl"
Type: filesandordirs; Name: "{app}\logs"
Type: files; Name: "{app}\LANGUAGE.txt"

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchApp}"; Flags: postinstall nowait skipifsilent runascurrentuser

[Code]
const
  FirewallRuleName = 'BirdNET-Go (TCP 8080)';

function LangCode(): String;
begin
  Result := ActiveLanguage();
  if Result = '' then Result := 'en';
end;

function FirewallParams(Add: Boolean): String;
begin
  if Add then
    Result := 'advfirewall firewall add rule name="' + FirewallRuleName + '" ' +
              'dir=in action=allow protocol=TCP localport=8080 profile=private,domain ' +
              'program="' + ExpandConstant('{app}\birdnet-go.exe') + '"'
  else
    Result := 'advfirewall firewall delete rule name="' + FirewallRuleName + '"';
end;

procedure ApplyFirewall(Add: Boolean);
var
  ErrorCode: Integer;
begin
  if ShellExec('runas', ExpandConstant('{sys}\netsh.exe'), FirewallParams(Add), '',
               SW_HIDE, ewWaitUntilTerminated, ErrorCode) then
    Log('Firewall: netsh exit ' + IntToStr(ErrorCode))
  else
    Log('Firewall: elevation refused (' + IntToStr(ErrorCode) + ')');
end;

procedure CurStepChanged(CurStep: TSetupStep);
begin
  if CurStep = ssPostInstall then
  begin
    SaveStringToFile(ExpandConstant('{app}\LANGUAGE.txt'), LangCode(), False);
    if (not WizardSilent) and WizardIsTaskSelected('firewall') then
      ApplyFirewall(True);
  end;
end;

procedure CurUninstallStepChanged(CurUninstallStep: TUninstallStep);
begin
  if (CurUninstallStep = usPostUninstall) and (not UninstallSilent) then
  begin
    if MsgBox(FmtMessage(CustomMessage('RemoveFirewall'), [FirewallRuleName]),
              mbConfirmation, MB_YESNO) = IDYES then
      ApplyFirewall(False);
  end;
end;
