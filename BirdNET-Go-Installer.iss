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

[Languages]
Name: "french"; MessagesFile: "compiler:Languages\French.isl"
Name: "english"; MessagesFile: "compiler:Default.isl"

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
  MsgText: String;
begin
  Result := True;
  IsUpdate := False;

  if Exec('cmd.exe', '/c tasklist /FI "IMAGENAME eq birdnet-go.exe" | find /I "birdnet-go.exe"', '', SW_HIDE, ewWaitUntilTerminated, ResultCode) then
  begin
    if ResultCode = 0 then
    begin
      if ActiveLanguage = 'french' then
        MsgText := 'BirdNET-Go est en cours d''exécution.' + #13#10 + 'L''installateur doit le fermer pour pouvoir le mettre à jour. Continuer ?'
      else
        MsgText := 'BirdNET-Go is currently running.' + #13#10 + 'The installer needs to close it to update. Continue?';

      if MsgBox(MsgText, mbConfirmation, MB_YESNO) = IDYES then
      begin
        Exec('taskkill.exe', '/F /IM birdnet-go.exe', '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
      end
      else
      begin
        Result := False;
        exit;
      end;
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
      MsgText := MsgText + #13#10 + #13#10 + 'Vos réglages (config.yaml) ont été conservés.' + #13#10 + 'L''interface est disponible sur : http://localhost:8080';
    end
    else
    begin
      if IsUpdate then MsgText := 'Update completed successfully!' else MsgText := 'Installation completed successfully!';
      MsgText := MsgText + #13#10 + #13#10 + 'Your settings (config.yaml) have been preserved.' + #13#10 + 'The interface is available at: http://localhost:8080';
    end;
    MsgBox(MsgText, mbInformation, MB_OK);
  end;
end;
