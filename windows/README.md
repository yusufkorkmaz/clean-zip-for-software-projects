# Clean Zip — For Windows

[Türkçe](README.tr.md) · [Choose another platform](../README.md)

Right-click a project folder to create a source-code ZIP beside it.

## Install and use

1. [Download CleanZip-Setup.exe](https://github.com/yusufkorkmaz/clean-zip-for-software-projects/releases/latest/download/CleanZip-Setup.exe) (about 2.2 MB) and run it.
2. Right-click the project folder, or an empty area inside it → **Clean Zip**. On Windows 11, check **Show more options**.
3. Find the ZIP beside the folder: `project` → `project.zip`.

The progress window closes when finished. Installation is for your current account; administrator rights and extra runtimes are not required. This release is unsigned, so Windows may show a security warning.

[Portable x64 ZIP](https://github.com/yusufkorkmaz/clean-zip-for-software-projects/releases/latest/download/CleanZip-Portable-x64.zip) · [Releases and checksums](https://github.com/yusufkorkmaz/clean-zip-for-software-projects/releases/latest)

## What goes in the ZIP?

Source code, regular JS/CSS, project definitions, lockfiles, SQL schemas and configuration are kept. Dependencies, build output, caches, compiled files, media, fonts, archives, Office/design files, installers, disk/database files, model weights and generated/temporary files are excluded. [Full rules](../CleanZip.rules.txt).

**`.env` files are included. Check for secrets before sharing.** The ZIP is for code review; excluded assets may be needed to run the project. Links are skipped. Source files stay unchanged; a completed ZIP replaces the old ZIP. Empty selections create no ZIP. UTF-8 filenames and ZIP64 are supported.

## Update or remove

Run the latest installer to update. Remove through **Installed apps → Clean Zip** or the Start menu shortcut. Custom rules survive updates and removal.

<details>
<summary>Install or update with PowerShell</summary>

Open **PowerShell 5.1 or 7 without administrator privileges** and paste the whole block. It downloads the latest Windows installer, verifies SHA-256 and installs or updates silently for your account.

```powershell
& {
    $ErrorActionPreference = 'Stop'
    $cleanZipRelease = Invoke-RestMethod -Uri 'https://api.github.com/repos/yusufkorkmaz/clean-zip-for-software-projects/releases/latest'
    $cleanZipUrl = "https://github.com/yusufkorkmaz/clean-zip-for-software-projects/releases/download/$($cleanZipRelease.tag_name)"
    $cleanZipSetup = Join-Path $env:TEMP ('CleanZip-Setup-' + [Guid]::NewGuid().ToString('N') + '.exe')
    try {
        Invoke-WebRequest -UseBasicParsing -Uri "$cleanZipUrl/CleanZip-Setup.exe" -OutFile $cleanZipSetup
        $cleanZipSums = (Invoke-WebRequest -UseBasicParsing -Uri "$cleanZipUrl/SHA256SUMS.txt").Content
        $cleanZipHash = [regex]::Match($cleanZipSums, '(?m)^([a-fA-F0-9]{64})\s+CleanZip-Setup\.exe\s*$').Groups[1].Value
        if (-not $cleanZipHash -or (Get-FileHash -LiteralPath $cleanZipSetup -Algorithm SHA256).Hash -ne $cleanZipHash) { throw 'Clean Zip checksum verification failed.' }
        $cleanZipProcess = Start-Process -FilePath $cleanZipSetup -ArgumentList '/VERYSILENT','/SUPPRESSMSGBOXES','/NORESTART' -WindowStyle Hidden -Wait -PassThru
        if ($cleanZipProcess.ExitCode -ne 0) { throw "Clean Zip installation failed: $($cleanZipProcess.ExitCode)" }
        Write-Output 'Clean Zip installed.'
    } finally {
        if (Test-Path -LiteralPath $cleanZipSetup) { Remove-Item -LiteralPath $cleanZipSetup -Force }
    }
}
```

</details>

<details>
<summary>Menu placement and compatibility</summary>

| Computer | Where to find Clean Zip |
| --- | --- |
| Windows 7–10, x86/x64 | Classic right-click menu |
| Windows 11 x64 | **Show more options** by default |
| Windows 11 x64, Developer Mode already enabled | Modern menu if registration succeeds; classic menu otherwise |
| Windows on ARM | Classic menu through x86/x64 emulation; no native ARM64 extension |

Version 2.0.1 prevents duplicate entries and restores the classic fallback when modern registration is unavailable. Setup preserves Windows menu/security settings, does not enable Developer Mode and does not install certificates. A trusted signed identity package is needed for the modern menu without Developer Mode; this release does not include one. [Microsoft documentation](https://learn.microsoft.com/en-us/windows/apps/desktop/modernize/grant-identity-to-nonpackaged-apps).

Windows 7 and later are compatibility targets. Automated tests run on current Windows; older versions and ARM have not each been tested in separate VMs.

</details>

<details>
<summary>Security warnings, duplicate entries or no ZIP</summary>

- **Unknown publisher / Windows protected your PC:** compare the installer hash with `SHA256SUMS.txt` from the same release. Use **More info → Run anyway** if offered.
- **Run anyway is missing:** a Windows policy may block continuing. See the policy details below; use an IT-approved installation on a managed computer.
- **Two entries:** install 2.0.1 or later and restart File Explorer if needed.
- **The progress window closes:** expected; check for the ZIP beside the folder.
- **No ZIP:** all files may be excluded, or the output may be unwritable/in use. Show errors with:

```powershell
& "$env:LOCALAPPDATA\CleanZip\CleanZip.exe" --path "C:\Projects\My Project" --no-ui
```

Check the installer hash:

```powershell
Get-FileHash .\CleanZip-Setup.exe -Algorithm SHA256
```

</details>

<details>
<summary>Custom rules and command line</summary>

Edit `%LOCALAPPDATA%\CleanZip\CleanZip.rules.txt`:

```text
d:node_modules
e:.pdf
s:.min.js
f:Thumbs.db
```

Rules ignore case: `d:` folder name at any depth, `e:` extension, `s:` filename suffix, `f:` exact filename. Excluded folders are not scanned.

Run these from the executable's folder:

```powershell
CleanZip.exe --path "C:\Projects\My Project" --scan-only --manifest "C:\Temp\selected.txt"
CleanZip.exe --path "C:\Projects\My Project" --output "C:\Archives\source.zip" --no-ui
```

Output and manifest must be outside the source folder. Use different ZIP and manifest targets.

</details>

<details>
<summary>Run anyway is missing: Windows policy steps</summary>

If **Run anyway** is missing, a SmartScreen policy can prevent users from continuing. An administrator can inspect the policy on editions with Local Group Policy Editor:

1. Press **Win + R**, enter `gpedit.msc`, and press Enter.
2. Open **Computer Configuration > Administrative Templates > Windows Components > Windows Defender SmartScreen > Explorer**.
3. Open **Configure Windows Defender SmartScreen**.

On a personal computer you own and administer, **Enabled > Warn** allows the confirmation while keeping SmartScreen warnings enabled; **Warn and prevent bypass** removes that option. This changes override behavior for all downloaded applications. On a managed work/school computer, ask IT for an approved installation instead of changing the organization's policy.

Turkish path: **Bilgisayar Yapılandırması > Yönetim Şablonları > Windows Bileşenleri > Windows Defender SmartScreen > Gezgin > Windows Defender SmartScreen'i yapılandır**; the choices are **Etkin > Uyar** and **Uyar ve geçişleri engelle**.

Clean Zip does not change SmartScreen policies. A valid signing certificate can still require reputation before warnings disappear. See Microsoft's [SmartScreen policy documentation](https://learn.microsoft.com/en-us/windows/client-management/mdm/policy-csp-smartscreen#preventoverrideforfilesinshell) and [app reputation documentation](https://learn.microsoft.com/en-us/windows/apps/package-and-deploy/smartscreen-reputation).

</details>

<details>
<summary>Restore the Windows 11 modern menu after a previous registry tweak</summary>

Run this in PowerShell as the affected desktop user. It backs up and removes only the empty per-user override used to force the old menu, then restart File Explorer or sign out and back in. It does not remove Windows' system component.

```powershell
$key = 'HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}'
$server = Join-Path $key 'InProcServer32'
if ((Test-Path -LiteralPath $server) -and
    [string]::IsNullOrEmpty((Get-Item -LiteralPath $server).GetValue(''))) {
    $backup = Join-Path ([Environment]::GetFolderPath('Desktop')) ('context-menu-' + (Get-Date -Format 'yyyyMMdd-HHmmss') + '.reg')
    & reg.exe export 'HKCU\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}' $backup /y
    if ($LASTEXITCODE -eq 0) { Remove-Item -LiteralPath $key -Recurse -Force }
}
```

If this override is absent, the script changes nothing; inspect the Windows customization tool that changed the menu.

</details>

<a id="build-and-test"></a>

<details>
<summary>Build and test for developers</summary>

Build requirements: Visual Studio C++ tools, Windows SDK, CMake 3.24+, Git, and Inno Setup 6.3+ for the installer. These are developer tools; users only need the installer. CMake retrieves [miniz 3.1.0](https://github.com/richgel999/miniz/tree/174573d60290f447c13a2b1b3405de2b96e27d6c), pinned to its commit.

Run from the repository root:

```powershell
.\Build-CleanZip.ps1 -Platform x64
.\Build-CleanZip.ps1 -Platform x86
.\tests\Test-Native.ps1 -Platform x64
.\tests\Test-Native.ps1 -Platform x86
.\Build-Assets.ps1
Copy-Item .\installer\AppxManifest.xml .\build\AppxManifest.xml
Copy-Item .\build\x64\_deps\miniz-src\LICENSE .\build\miniz-LICENSE.txt
& 'C:\Program Files (x86)\Inno Setup 6\ISCC.exe' .\installer\CleanZip.iss
```

Tests verify exact archive entries and data, all exclusion categories, Unicode, spaces, brackets, hidden files, mixed-case extensions, native COM activation and folder/file command states. Native PE headers are checked for the absence of a CLR/.NET runtime header. Installer tests verify the menu commands, installed ZIP creation, rule preservation and uninstall cleanup.

</details>

MIT license. The installer includes miniz's MIT license.
