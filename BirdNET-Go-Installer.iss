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
; On inclut le binaire et l'icône. 
; IMPORTANT : On n'inclut PAS config.yaml ici. 
; Ainsi, lors d'une mise à jour, Inno Setup remplace l'ancien .exe 
; mais ne touchera pas au fichier config.yaml existant !
Source: "dist\birdnet-go.exe"; DestDir: "{app}"; Flags: ignoreversion
Source: "dist\VERSION.txt"; DestDir: "{app}"; Flags: ignoreversion
Source: "icon.ico"; DestDir: "{app}"; Flags: ignoreversion

[Icons]
; Raccourci sur le Bureau
Name: "{autodesktop}\BirdNET-Go"; Filename: "{app}\birdnet-go.exe"; WorkingDir: "{app}"; IconFilename: "{app}\icon.ico"
; Raccourci dans le menu Démarrer
Name: "{group}\BirdNET-Go"; Filename: "{app}\birdnet-go.exe"; WorkingDir: "{app}"; IconFilename: "{app}\icon.ico"
; Raccourci pour Désinstaller
Name: "{group}\Désinstaller BirdNET-Go"; Filename: "{uninstallexe}"

[Registry]
; Ajout du dossier au PATH
Root: HKCU; Subkey: "Environment"; ValueType: expandsz; ValueName: "Path"; ValueData: "{olddata};{app}"; Check: NeedsAddPath('{app}')

[Run]
; On propose de lancer l'application à la fin
Filename: "{app}\birdnet-go.exe"; Description: "Lancer BirdNET-Go"; Flags: nowait postinstall skipifsilent

[Code]
{ Vérification du PATH }
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

{ Message final indiquant l'adresse localhost }
procedure CurStepChanged(CurStep: TSetupStep);
var
  MsgText: String;
begin
  if CurStep = ssPostInstall then
  begin
    // Détection de la langue pour afficher le bon message
    if ActiveLanguage = 'french' then
      MsgText := 'Installation terminée avec succès !' + #13#10 + #13#10 +
                 'Pour utiliser BirdNET-Go, ouvrez votre navigateur Web et allez à l''adresse :' + #13#10 +
                 'http://localhost:8080' + #13#10 + #13#10 +
                 '(Une fenêtre noire va s''ouvrir. Gardez-la ouverte, c''est le serveur !)'
    else
      MsgText := 'Installation completed successfully!' + #13#10 + #13#10 +
                 'To use BirdNET-Go, open your web browser and go to:' + #13#10 +
                 'http://localhost:8080' + #13#10 + #13#10 +
                 '(A black window will open. Keep it open, it is the server!)';
                 
    MsgBox(MsgText, mbInformation, MB_OK);
  end;
end;
