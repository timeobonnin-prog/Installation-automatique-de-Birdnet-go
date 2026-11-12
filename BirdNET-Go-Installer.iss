; -- BirdNET-Go-Installer.iss --
; Compile un .exe Windows qui exécute install-birdnet.ps1.

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
Source: "install-birdnet.ps1"; DestDir: "{tmp}"; Flags: deleteafterinstall

[Run]
Filename: "powershell.exe"; \
  Parameters: "-ExecutionPolicy Bypass -NoLogo -NoProfile -WindowStyle Hidden -File ""{tmp}\install-birdnet.ps1"""; \
  Flags: runhidden waituntilterminated

[Code]
procedure CurStepChanged(CurStep: TSetupStep);
begin
  if CurStep = ssPostInstall then
    MsgBox('BirdNET-Go a été installé dans ' + ExpandConstant('{localappdata}\BirdNET-Go'), mbInformation, MB_OK);
end;
