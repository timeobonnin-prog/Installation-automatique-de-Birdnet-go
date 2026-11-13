[Setup]
AppName=BirdNET-Go
AppVersion=1.0.0
AppPublisher=timeobonnin-prog
DefaultDirName={localappdata}\BirdNET-Go
DefaultGroupName=BirdNET-Go
DisableProgramGroupPage=yes
OutputDir=Output
OutputBaseFilename=BirdNET-Go-Windows
Compression=lzma2
SolidCompression=yes
ArchitecturesInstallIn64BitMode=x64compatible
WizardStyle=modern
PrivilegesRequired=lowest
ChangesEnvironment=yes
SetupIconFile=icon.ico

; --- GESTION DES LANGUES (Français et Anglais) ---
[Languages]
Name: "french"; MessagesFile: "compiler:Languages\French.isl"
Name: "english"; MessagesFile: "compiler:Default.isl"

[Files]
; On inclut le binaire, le script de lancement et l'icône
Source: "dist\birdnet-go.exe"; DestDir: "{app}"; Flags: ignoreversion
Source: "start_birdnet.bat"; DestDir: "{app}"; Flags: ignoreversion
Source: "dist\VERSION.txt"; DestDir: "{app}"; Flags: ignoreversion
Source: "icon.ico"; DestDir: "{app}"; Flags: ignoreversion

[Icons]
; Raccourci sur le Bureau : Lance le serveur ET ouvre le navigateur
Name: "{autodesktop}\BirdNET-Go"; Filename: "{app}\start_birdnet.bat"; WorkingDir: "{app}"; IconFilename: "{app}\icon.ico"

; Raccourci dans le menu Démarrer
Name: "{group}\Lancer BirdNET-Go"; Filename: "{app}\start_birdnet.bat"; WorkingDir: "{app}"; IconFilename: "{app}\icon.ico"

; Raccourci de Désinstallation (UNIQUEMENT dans le menu Démarrer, pas sur le bureau)
Name: "{group}\Désinstaller BirdNET-Go"; Filename: "{uninstallexe}"

[Registry]
; Ajout du dossier au PATH
Root: HKCU; Subkey: "Environment"; ValueType: expandsz; ValueName: "Path"; ValueData: "{olddata};{app}"; Check: NeedsAddPath('{app}')

[Code]
{ Vérification pour ne pas dupliquer le dossier dans le PATH }
function NeedsAddPath(Param: string): boolean;
var
  OrigPath: string;
begin
  if not RegQueryStringValue(HKEY_CURRENT_USER, 'Environment', 'Path', OrigPath)
  then begin
    Result := True;
    exit;
  end;
  Result := Pos(';' + Param + ';', ';' + OrigPath + ';') = 0;
end;
