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
Source: "BirdNET-Go-Tray.ps1"; DestDir: "{app}"; Flags: ignoreversion
Source: "dist\VERSION.txt"; DestDir: "{app}"; Flags: ignoreversion
Source: "icon.ico"; DestDir: "{app}"; Flags: ignoreversion

[Icons]
Name: "{autodesktop}\BirdNET-Go"; Filename: "powershell.exe"; Parameters: "-ExecutionPolicy Bypass -WindowStyle Hidden -File ""{app}\BirdNET-Go-Tray.ps1"""; WorkingDir: "{app}"; IconFilename: "{app}\icon.ico"
Name: "{group}\Lancer BirdNET-Go"; Filename: "powershell.exe"; Parameters: "-ExecutionPolicy Bypass -WindowStyle Hidden -File ""{app}\BirdNET-Go-Tray.ps1"""; WorkingDir: "{app}"; IconFilename: "{app}\icon.ico"
Name: "{group}\Désinstaller BirdNET-Go"; Filename: "{uninstallexe}"

[Registry]
Root: HKCU; Subkey: "Environment"; ValueType: expandsz; ValueName: "Path"; ValueData: "{olddata};{app}"; Check: NeedsAddPath('{app}')

[Run]
Filename: "netsh"; Parameters: "advfirewall firewall add rule name=""BirdNET-Go Server"" dir=in action=allow protocol=TCP localport=8080"; Flags: runhidden; Tasks: firewall

[UninstallRun]
; CORRECTION ICI : Le guillemet fermant a été ajouté à la fin
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
  if Exec('cmd.exe', '/c tasklist /FI "IMAGENAME eq birdnet-go.exe" | find /I "birdnet-go.exe"', '', SW_HIDE, ewWaitUntilTerminated, ResultCode) then
  begin
    if ResultCode = 0 then
    begin
      Exec('taskkill.exe', '/F /IM birdnet-go.exe', '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
    end;
  end;
  if RegKeyExists(HKEY_CURRENT_USER, 'Software\Microsoft\Windows\CurrentVersion\Uninstall\BirdNET-Go_is1') then
    IsUpdate := True;
end;

procedure CurStepChanged(CurStep: TSetupStep);
var
  MsgText: String;
begin
  if CurStep = ssPostInstall then
  begin
    if ActiveLanguage = 'french' then
    begin
      if IsUpdate then MsgText := 'Mise à jour terminée avec succès !' else MsgText := 'Installation terminée avec succès !';
      MsgText := MsgText + #13#10 + #13#10 + 'Vos réglages et vos sons ont été conservés.' + #13#10 + 'Une icône BirdNET-Go est maintenant dans votre barre des tâches.';
    end
    else
    begin
      if IsUpdate then MsgText := 'Update completed successfully!' else MsgText := 'Installation completed successfully!';
      MsgText := MsgText + #13#10 + #13#10 + 'Your settings and clips have been preserved.' + #13#10 + 'A BirdNET-Go icon is now in your system tray.';
    end;
    MsgBox(MsgText, mbInformation, MB_OK);
  end;
end;

[CustomMessages]
french.FirewallTask=Autoriser BirdNET-Go dans le Pare-feu Windows (Port 8080)
french.AdditionalIcons=Options supplémentaires :
english.FirewallTask=Allow BirdNET-Go in Windows Firewall (Port 8080)
english.AdditionalIcons=Additional options:
