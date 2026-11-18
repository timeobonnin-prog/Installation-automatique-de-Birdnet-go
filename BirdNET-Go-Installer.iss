; ---------------------------------------------------------------
;  BirdNET-Go - Installateur Windows (Inno Setup 6) - USER SCOPE
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

; --- USER SCOPE : pas d'UAC pour l'installation elle-même ---
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

; Single-instance : ferme proprement le contrôleur pendant l'install/MAJ
AppMutex=BirdNETGoControl_SingleInstance_Mutex
CloseApplications=yes
RestartApplications=no

[Languages]
Name: "french"; MessagesFile: "compiler:Languages\French.isl"
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "Créer un raccourci sur le Bureau"; GroupDescription: "Raccourcis :"; Flags: unchecked
; Règle pare-feu : OPTIONNELLE, décochée, et masquée en mode silencieux (CI-safe)
Name: "firewall"; Description: "Autoriser l'accès réseau (LAN) au port 8080 — demande les droits administrateur"; GroupDescription: "Réseau :"; Flags: unchecked; Check: not WizardSilent

[Files]
Source: "dist\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "icon.ico"; DestDir: "{app}"; Flags: ignoreversion
Source: "start_birdnet.bat"; DestDir: "{app}"; Flags: ignoreversion skipifsourcedoesntexist

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; IconFilename: "{app}\icon.ico"
Name: "{group}\Désinstaller {#MyAppName}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; IconFilename: "{app}\icon.ico"; Tasks: desktopicon

[Registry]
Root: HKCU; Subkey: "Software\Microsoft\Windows\CurrentVersion\Run"; ValueType: none; ValueName: "BirdNETGoControl"; Flags: uninsdeletevalue

[UninstallRun]
Filename: "{cmd}"; Parameters: "/C taskkill /F /IM birdnet-go.exe"; Flags: runhidden; RunOnceId: "KillBirdnetServer"
Filename: "{cmd}"; Parameters: "/C taskkill /F /IM {#MyAppExeName}"; Flags: runhidden; RunOnceId: "KillBirdnetControl"

[UninstallDelete]
Type: filesandordirs; Name: "{userappdata}\BirdNETGoControl"
Type: filesandordirs; Name: "{app}\logs"

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "Lancer {#MyAppName}"; Flags: postinstall nowait skipifsilent runascurrentuser

[Code]
const
  FirewallRuleName = 'BirdNET-Go (TCP 8080)';

// Construit la ligne de commande netsh (ajout ciblé sur l'exe + port, profils privé/domaine)
function FirewallParams(Add: Boolean): String;
begin
  if Add then
    Result := 'advfirewall firewall add rule name="' + FirewallRuleName + '" ' +
              'dir=in action=allow protocol=TCP localport=8080 profile=private,domain ' +
              'program="' + ExpandConstant('{app}\birdnet-go.exe') + '"'
  else
    Result := 'advfirewall firewall delete rule name="' + FirewallRuleName + '"';
end;

// Exécute netsh avec élévation UAC à la demande (l'install reste sans admin)
procedure ApplyFirewall(Add: Boolean);
var
  ErrorCode: Integer;
begin
  if ShellExec('runas', ExpandConstant('{sys}\netsh.exe'), FirewallParams(Add), '',
               SW_HIDE, ewWaitUntilTerminated, ErrorCode) then
  begin
    if ErrorCode = 0 then
      Log('Pare-feu : règle "' + FirewallRuleName + '" appliquée.')
    else
      Log('Pare-feu : netsh a renvoyé le code ' + IntToStr(ErrorCode));
  end
  else
    Log('Pare-feu : élévation refusée ou impossible (code ' + IntToStr(ErrorCode) + ').');
end;

procedure CurStepChanged(CurStep: TSetupStep);
begin
  // Jamais en silencieux : aucun prompt UAC ne doit bloquer une install auto / CI
  if (CurStep = ssPostInstall) and (not WizardSilent) and WizardIsTaskSelected('firewall') then
    ApplyFirewall(True);
end;

procedure CurUninstallStepChanged(CurUninstallStep: TUninstallStep);
begin
  // Nettoyage proposé uniquement en désinstallation interactive
  if (CurUninstallStep = usPostUninstall) and (not UninstallSilent) then
  begin
    if MsgBox('Supprimer la règle de pare-feu "' + FirewallRuleName + '" ?',
              mbConfirmation, MB_YESNO) = IDYES then
      ApplyFirewall(False);
  end;
end;
