; -- BirdNET-Go-Installer.iss --
; Script Inno Setup pour créer l'installateur Windows de BirdNET-Go.

[Setup]
AppName=BirdNET-Go (Auto-Installer)
AppVersion=1.0.0
AppPublisher=timeobonnin-prog
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
; Embarque le script PowerShell dans le dossier temporaire de l'installateur.
Source: "install-birdnet.ps1"; DestDir: "{tmp}"; Flags: deleteafterinstall

[Run]
; Exécute le script après l'installation, sans fenêtre, et attend la fin.
Filename: "powershell.exe"; \
  Parameters: "-ExecutionPolicy Bypass -NoLogo -NoProfile -WindowStyle Hidden -File ""{tmp}\install-birdnet.ps1"""; \
  Flags: runhidden waituntilterminated

[Code]
; Optionnel : affiche un message à la fin.
procedure CurStepChanged(CurStep: TSetupStep);
begin
  if CurStep = ssPostInstall then
  begin
    MsgBox('BirdNET-Go a été installé avec succès dans ' + ExpandConstant('{localappdata}\BirdNET-Go'), mbInformation, MB_OK);
  end;
end;
