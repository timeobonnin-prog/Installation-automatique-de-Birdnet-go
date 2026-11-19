; ---------------------------------------------------------------
;  BirdNET-Go - Installateur Windows (Inno Setup 6) - USER SCOPE
;  Multilingue FR / EN / DE / ES + écrit LANGUAGE.txt pour l'app
; ---------------------------------------------------------------

#define MyAppName "BirdNET-Go"
#define MyAppExeName "BirdNET-Go-Control.exe"
#define MyAppPublisher "timeobonnin-prog"
#define MyAppURL "https://github.com/timeobonnin-prog/Installation-automatique-de-Birdnet-go"

[Setup]
; ⚠️ Garde ton AppId existant si tu en as un !
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

; Affiche le choix de la langue à l'installation
ShowLanguageDialog=yes

AppMutex=BirdNETGoControl_SingleInstance_Mutex
CloseApplications=yes
RestartApplications=no

[Languages]
Name: "fr"; MessagesFile: "compiler:Languages\French.isl"
Name: "en"; MessagesFile: "compiler:Default.isl"
Name: "de"; MessagesFile: "compiler:Languages\German.isl"
Name: "es"; MessagesFile: "compiler:Languages\Spanish.isl"

[CustomMessages]
fr.TaskDesktop=Créer un raccourci sur le Bureau
en.TaskDesktop=Create a desktop shortcut
de.TaskDesktop=Desktop-Verknüpfung erstellen
es.TaskDesktop=Crear acceso directo en el escritorio

fr.TaskFirewall=Autoriser l'accès réseau (LAN) au port 8080 - demande les droits administrateur
en.TaskFirewall=Allow network (LAN) access on port 8080 - requires administrator rights
de.TaskFirewall=Netzwerkzugriff (LAN) auf Port 8080 erlauben - erfordert Administratorrechte
es.TaskFirewall=Permitir acceso de red (LAN) al puerto 8080 - requiere derechos de administrador

fr.GroupShortcuts=Raccourcis :
en.GroupShortcuts=Shortcuts:
de.GroupShortcuts=Verknüpfungen:
es.GroupShortcuts=Accesos directos:

fr.GroupNetwork=Réseau :
en.GroupNetwork=Network:
de.GroupNetwork=Netzwerk:
es.GroupNetwork=Red:

fr.LaunchApp=Lancer BirdNET-Go
en.LaunchApp=Launch BirdNET-Go
de.LaunchApp=BirdNET-Go starten
es.LaunchApp=Iniciar BirdNET-Go

fr.RemoveFirewall=Supprimer la règle de pare-feu "%1" ?
en.RemoveFirewall=Remove the firewall rule "%1"?
de.RemoveFirewall=Firewall-Regel "%1" entfernen?
es.RemoveFirewall=¿Eliminar la regla de firewall "%1"?

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
  case ActiveLanguage() of
    'fr': Result := 'fr';
    'de': Result := 'de';
    'es': Result := 'es';
  else
    Result := 'en';
  end;
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
  begin
    if ErrorCode = 0 then
      Log('Pare-feu : regle appliquee.')
    else
      Log('Pare-feu : netsh code ' + IntToStr(ErrorCode));
  end
  else
    Log('Pare-feu : elevation refusee (code ' + IntToStr(ErrorCode) + ').');
end;

procedure CurStepChanged(CurStep: TSetupStep);
begin
  if CurStep = ssPostInstall then
  begin
    // Transmet la langue choisie a l'app (lue par Loc.Init en mode "auto")
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
