; ---------------------------------------------------------------
;  BirdNET-Go - Installateur Windows (Inno Setup 6)
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
DefaultDirName={autopf}\BirdNET-Go
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
PrivilegesRequired=admin
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
Filename: "{app}\{#MyAppExeName}"; Flags: nowait runascurrentuser; Check: WizardSilent
