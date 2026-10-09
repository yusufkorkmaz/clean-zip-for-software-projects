#define AppVersion "2.0.0"
[Setup]
AppId={{9129BAAA-942C-43EE-BC17-C3593AC2A1BA}
AppName=Clean Zip
AppVersion={#AppVersion}
AppPublisher=Yusuf Korkmaz
AppPublisherURL=https://yusufkorkmaz.dev
AppSupportURL=https://github.com/yusufkorkmaz/clean-zip-for-software-projects
AppUpdatesURL=https://github.com/yusufkorkmaz/clean-zip-for-software-projects/releases
DefaultDirName={localappdata}\CleanZip
DisableProgramGroupPage=yes
PrivilegesRequired=lowest
MinVersion=6.1
ArchitecturesAllowed=x86compatible
ArchitecturesInstallIn64BitMode=x64compatible
OutputDir=..\dist
OutputBaseFilename=CleanZip-Setup
Compression=lzma2/fast
SolidCompression=yes
WizardStyle=modern
UninstallDisplayIcon={app}\Assets\CleanZip.ico
SetupIconFile=..\build\Assets\CleanZip.ico
CloseApplications=yes
RestartApplications=no
LicenseFile=..\LICENSE
InfoBeforeFile=INSTALL-NOTES.txt

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"
Name: "turkish"; MessagesFile: "compiler:Languages\Turkish.isl"

[Files]
Source: "..\build\x64\Release\CleanZip.exe"; DestDir: "{app}"; Flags: ignoreversion; Check: IsX64Compatible
Source: "..\build\x86\Release\CleanZip.exe"; DestDir: "{app}"; Flags: ignoreversion; Check: not IsX64Compatible
Source: "..\CleanZip.rules.txt"; DestDir: "{app}"; Flags: onlyifdoesntexist uninsneveruninstall
Source: "..\build\x64\Release\CleanZip.Shell.dll"; DestDir: "{app}\modern-{#AppVersion}"; Flags: ignoreversion; Check: IsX64OS
Source: "..\build\Assets\*"; DestDir: "{app}\Assets"; Flags: ignoreversion
Source: "..\build\AppxManifest.xml"; DestDir: "{app}"; Flags: ignoreversion; Check: IsX64OS
Source: "Register-ModernMenu.ps1"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\LICENSE"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\build\miniz-LICENSE.txt"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\CleanZip.ps1"; DestDir: "{app}"; Flags: ignoreversion
#if FileExists("..\build\CleanZip.Identity.msix")
Source: "..\build\CleanZip.Identity.msix"; DestDir: "{app}"; Flags: ignoreversion; Check: IsX64OS
#endif

[Registry]
Root: HKCU; Subkey: "Software\Classes\Directory\shell\CleanZip"; ValueType: string; ValueName: ""; ValueData: "Clean Zip"; Flags: uninsdeletekey
Root: HKCU; Subkey: "Software\Classes\Directory\shell\CleanZip"; ValueType: string; ValueName: "Icon"; ValueData: "{app}\Assets\CleanZip.ico"
Root: HKCU; Subkey: "Software\Classes\Directory\shell\CleanZip"; ValueType: string; ValueName: "MultiSelectModel"; ValueData: "Single"
Root: HKCU; Subkey: "Software\Classes\Directory\shell\CleanZip\command"; ValueType: string; ValueName: ""; ValueData: """{app}\CleanZip.exe"" --path ""%1"" --no-ui"
Root: HKCU; Subkey: "Software\Classes\Directory\Background\shell\CleanZip"; ValueType: string; ValueName: ""; ValueData: "Clean Zip"; Flags: uninsdeletekey
Root: HKCU; Subkey: "Software\Classes\Directory\Background\shell\CleanZip"; ValueType: string; ValueName: "Icon"; ValueData: "{app}\Assets\CleanZip.ico"
Root: HKCU; Subkey: "Software\Classes\Directory\Background\shell\CleanZip\command"; ValueType: string; ValueName: ""; ValueData: """{app}\CleanZip.exe"" --path ""%V"" --no-ui"

[Icons]
Name: "{userprograms}\Clean Zip\Exclusion rules"; Filename: "{app}\CleanZip.rules.txt"
Name: "{userprograms}\Clean Zip\GitHub"; Filename: "https://github.com/yusufkorkmaz/clean-zip-for-software-projects"
Name: "{userprograms}\Clean Zip\Uninstall Clean Zip"; Filename: "{uninstallexe}"

[Code]
procedure NotifyExplorer(Event: Integer; Flags: Cardinal; Item1, Item2: Integer);
external 'SHChangeNotify@shell32.dll stdcall';

procedure CurStepChanged(CurStep: TSetupStep);
var Code: Integer;
begin
  if CurStep = ssPostInstall then
  begin
    if IsX64OS and (GetWindowsVersion >= $0A000000) then
      Exec(ExpandConstant('{sys}\WindowsPowerShell\v1.0\powershell.exe'),
        '-NoProfile -NonInteractive -ExecutionPolicy Bypass -File "' + ExpandConstant('{app}\Register-ModernMenu.ps1') + '" -InstallationDirectory "' + ExpandConstant('{app}') + '"',
        '', SW_HIDE, ewWaitUntilTerminated, Code);
    NotifyExplorer($08000000, 0, 0, 0);
  end;
end;

procedure CurUninstallStepChanged(CurUninstallStep: TUninstallStep);
var Code: Integer;
begin
  if CurUninstallStep = usUninstall then
  begin
    if IsX64OS and (GetWindowsVersion >= $0A000000) then
      Exec(ExpandConstant('{sys}\WindowsPowerShell\v1.0\powershell.exe'),
        '-NoProfile -NonInteractive -ExecutionPolicy Bypass -File "' + ExpandConstant('{app}\Register-ModernMenu.ps1') + '" -InstallationDirectory "' + ExpandConstant('{app}') + '" -Remove',
        '', SW_HIDE, ewWaitUntilTerminated, Code);
    NotifyExplorer($08000000, 0, 0, 0);
  end;
end;

[UninstallDelete]
Type: files; Name: "{app}\modern-installed.txt"
Type: files; Name: "{app}\menu-install.log"
