[Setup]
AppName=BirdNET-Go
AppVersion=1.0.0
AppPublisher=timeobonnin-prog
VersionInfoVersion=1.0.0.0
DefaultDirName={localappdata}\BirdNET-Go
DefaultGroupName=BirdNET-Go
DisableProgramGroupPage=yes
OutputDir=Output
OutputBaseFilename=BirdNET-Go-Installer
Compression=lzma2
SolidCompression=yes
ArchitecturesInstallIn64BitMode=x64compatible
WizardStyle=modern
PrivilegesRequired=lowest

[Files]
; Le script de configuration
Source: "install-birdnet.ps1"; DestDir: "{tmp}"; Flags: deleteafterinstall
; Le binaire extrait par le workflow GitHub Actions
Source: "dist\birdnet-go.exe"; DestDir: "{app}"; Flags: ignoreversion
; Le fichier de version pour l'affichage
Source: "dist\VERSION.txt"; DestDir: "{app}"; Flags: ignoreversion

[Run]
; On passe le dossier d'installation en paramètre au script
Filename: "powershell.exe"; \
  Parameters: "-ExecutionPolicy Bypass -NoLogo -NoProfile -File ""{tmp}\install-birdnet.ps1"" -InstallDir ""{app}"""; \
  Flags: waituntilterminated

[Code]
procedure CurStepChanged(CurStep: TSetupStep);
begin
  if CurStep = ssPostInstall then
    MsgBox('BirdNET-Go a été installé avec succès dans ' + ExpandConstant('{app}'), mbInformation, MB_OK);
end;
