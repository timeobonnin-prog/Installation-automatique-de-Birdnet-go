[Setup]
AppName=BirdNET-Go (Community Installer)
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

[Languages]
Name: "french"; MessagesFile: "compiler:Languages\French.isl"
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "firewall"; Description: "{cm:FirewallTask}"; GroupDescription: "{cm:AdditionalIcons}"

[Files]
Source: "dist\birdnet-go.exe"; DestDir: "{app}"; Flags: ignoreversion
Source: "dist\ffmpeg.exe"; DestDir: "{app}"; Flags: ignoreversion
Source: "dist\ffprobe.exe"; DestDir: "{app}"; Flags: ignoreversion
Source: "start_birdnet.bat"; DestDir: "{app}"; Flags: ignoreversion
Source: "dist\VERSION.txt"; DestDir: "{app}"; Flags: ignoreversion
Source: "icon.ico"; DestDir: "{app}"; Flags: ignoreversion

[Icons]
Name: "{autodesktop}\BirdNET-Go"; Filename: "{app}\start_birdnet.bat"; WorkingDir: "{app}"; IconFilename: "{app}\icon.ico"
Name: "{group}\Lancer BirdNET-Go"; Filename: "{app}\start_birdnet.bat"; WorkingDir: "{app}"; IconFilename: "{app}\icon.ico"
Name: "{group}\Désinstaller BirdNET-Go"; Filename: "{uninstallexe}"

[Registry]
Root: HKCU; Subkey: "Environment"; ValueType: expandsz; ValueName: "Path"; ValueData: "{olddata};{app}"; Check: NeedsAddPath('{app}')

[Run]
Filename: "netsh"; Parameters: "advfirewall firewall add rule name=""BirdNET-Go Server"" dir=in action=allow protocol=TCP localport=8080"; Flags: runhidden; Tasks: firewall

[UninstallRun]
; CORRECTION ICI : Le guillemet fermant a été ajouté à la fin de la commande
Filename: "netsh"; Parameters: "advfirewall firewall delete rule name=""BirdNET-Go Server"""; Flags: runhidden

[Code]
var
  IsUpdate: Boolean;

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

function InitializeSetup(): Boolean;
var
  ResultCode: Integer;
begin
  Result := True;
  IsUpdate := False;

  { Vérifie si BirdNET-Go tourne }
  if Exec('cmd.exe', '/c tasklist /FI "IMAGENAME eq birdnet-go.exe" | find /I "birdnet-go.exe"', '', SW_HIDE, ewWaitUntilTerminated, ResultCode) then
  begin
    if ResultCode = 0 then
    begin
      Exec('taskkill.exe', '/F /IM birdnet-go.exe', '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
    end;
  end;

  { Vérifie si c'est une mise à jour }
  if RegKeyExists(HKEY_CURRENT_USER, 'Software\Microsoft\Windows\CurrentVersion\Uninstall\BirdNET-Go_is1') then
    IsUpdate := True;
end;

{ Ajout des traductions pour la case à cocher }
[CustomMessages]
french.FirewallTask=Autoriser BirdNET-Go dans le Pare-feu Windows (Port 8080)
french.AdditionalIcons=Options supplémentaires :
english.FirewallTask=Allow BirdNET-Go in Windows Firewall (Port 8080)
english.AdditionalIcons=Additional options:
