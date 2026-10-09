# Clean Zip for Software Projects

Right-click a project folder and choose **Clean Zip** to create a source ZIP beside it, excluding dependencies, build output and common binary/media files.

**[Download the Windows installer](https://github.com/yusufkorkmaz/clean-zip-for-software-projects/releases/latest/download/CleanZip-Setup.exe)** · **[Türkçe anlatım](README.tr.md)**

### Prefer installing from the command line?

Open **PowerShell 5.1 or 7 without administrator privileges**, then paste this entire block. It downloads the latest released EXE, verifies its SHA256 checksum and installs or updates Clean Zip silently for your current account.

```powershell
& {
    $ErrorActionPreference = 'Stop'
    $cleanZipRelease = Invoke-RestMethod -Uri 'https://api.github.com/repos/yusufkorkmaz/clean-zip-for-software-projects/releases/latest'
    $cleanZipUrl = "https://github.com/yusufkorkmaz/clean-zip-for-software-projects/releases/download/$($cleanZipRelease.tag_name)"
    $cleanZipSetup = Join-Path $env:TEMP ('CleanZip-Setup-' + [Guid]::NewGuid().ToString('N') + '.exe')
    try {
        Invoke-WebRequest -UseBasicParsing -Uri "$cleanZipUrl/CleanZip-Setup.exe" -OutFile $cleanZipSetup
        $cleanZipSums = (Invoke-WebRequest -UseBasicParsing -Uri "$cleanZipUrl/SHA256SUMS.txt").Content
        $cleanZipHash = [regex]::Match($cleanZipSums, '(?m)^([a-fA-F0-9]{64})\s+CleanZip-Setup\.exe\s*(https://github.com/yusufkorkmaz/clean-zip-for-software-projects/releases/latest/download/CleanZip-Portable-x64.zip) · [Release notes and checksums](https://github.com/yusufkorkmaz/clean-zip-for-software-projects/releases/latest)

## Install and use

1. Download and run **CleanZip-Setup.exe** (about 2.2 MB).
2. Right-click a project folder or an empty area inside it, then choose **Clean Zip**.
3. Find `project.zip` beside `project`. The progress console closes automatically without a completion alert.

Installation is for your current Windows account. Administrator permission, .NET, Node.js, a Visual C++ redistributable and 7-Zip are not required. This release is **unsigned**, so Windows may show a SmartScreen warning.

## Where is Clean Zip?

| Computer | Menu in this unsigned release |
| --- | --- |
| Windows 7, 8, 8.1 or 10, x86/x64 | Classic right-click menu |
| Windows 11 x64, Developer Mode off | **Show more options > Clean Zip** |
| Windows 11 x64, Developer Mode already on | Modern menu if registration succeeds; otherwise **Show more options** |
| Windows on ARM | Classic menu through x86/x64 emulation; no native ARM64 extension |

**2.0.1 fixes duplicate entries:** when the modern command is available, setup hides the extra classic entry. Updates restore the classic entry when modern registration is unavailable.

Setup does not change your Windows menu preference, enable Developer Mode, import certificates or alter SmartScreen. A trusted signed identity package is needed to register the modern menu without Developer Mode ([Microsoft documentation](https://learn.microsoft.com/en-us/windows/apps/desktop/modernize/grant-identity-to-nonpackaged-apps)); this release does not include one.

Windows 7 and later are compatibility targets. Automated tests run on current Windows; installation on every older version and ARM has not been verified in separate VMs.

## Common situations

| Situation | What to do |
| --- | --- |
| **Windows protected your PC / Unknown publisher** | Verify the release checksum, then choose **More info > Run anyway** if offered. Turkish: **Ek bilgi > Yine de çalıştır**. |
| **Run anyway** is missing | A Windows policy can block continuing. See the policy steps below; on a managed computer, ask IT. |
| Windows 11 still opens the classic menu | A previous Windows customization can force it. Setup preserves this preference. See the restore steps below. |
| Two **Clean Zip** entries | Install **2.0.1 or later**, then restart File Explorer if the old menu is still cached. |
| The console closes without an alert | Expected behavior. Check for the ZIP beside the source folder. |
| No new ZIP appears | All files may be excluded, or the destination may be unwritable/in use. Run the command below in PowerShell to see the result or error. |

Verify the installer against `SHA256SUMS.txt` from the same release:

```powershell
Get-FileHash .\CleanZip-Setup.exe -Algorithm SHA256
```

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

## What is excluded?

| Content | Examples |
| --- | --- |
| Dependencies, build output and caches | `node_modules`, `.next`, `bin`, `obj`, `dist`, `.git`, virtual environments |
| Compiled files | `.dll`, `.exe`, `.pdb`, `.class`, `.pyc` |
| Media, fonts and archives | Images, videos, audio, PDF, ZIP, fonts |
| Office and design files | PowerPoint, Word, Excel, PSD, AI, XD, Sketch |
| Installers, disk files, database data and model weights | MSI, ISO, DB, MDF, ONNX, PT |
| Generated and temporary files | `.min.js`, `.min.css`, source maps, logs, dumps, temp files |

Ordinary JS/CSS and other source code, manifests, lockfiles, SQL schemas and configuration are kept. **`.env` files are kept too**; review secrets before sharing. This is a source-review ZIP: excluded images and other assets may be needed to run the complete application.

See [the full default exclusion list](CleanZip.rules.txt). Customize `%LOCALAPPDATA%\CleanZip\CleanZip.rules.txt`:

```text
d:node_modules
e:.pdf
s:.min.js
f:Thumbs.db
```

Rules ignore letter case: `d:` directory name at any depth, `e:` extension, `s:` filename suffix, `f:` exact filename. Excluded folders are skipped before scanning; links/reparse points are skipped.

## Update, uninstall and ZIP behavior

Run the latest installer to update. Uninstall from **Installed apps > Clean Zip** or the Start menu shortcut. Custom exclusion rules survive both updates and uninstallation.

Source files are never modified. UTF-8 filenames and ZIP64 are supported. An existing ZIP is replaced only after the new ZIP is complete; a failed run preserves the previous ZIP. An empty selection creates no ZIP.

## Command line

```powershell
& "$env:LOCALAPPDATA\CleanZip\CleanZip.exe" --path "C:\Projects\My Project" --no-ui
```

<details>
<summary>Preview selected files or choose another output</summary>

```powershell
CleanZip.exe --path "C:\Projects\My Project" --scan-only --manifest "C:\Temp\selected.txt"
CleanZip.exe --path "C:\Projects\My Project" --output "C:\Archives\source.zip" --no-ui
```

Use these commands from the executable's folder. Output and manifest paths must be outside the source folder.

</details>

<details>
<summary>Build and test for developers</summary>

Build requirements: Visual Studio C++ tools, Windows SDK, CMake 3.24+, Git, and Inno Setup 6.3+ for the installer. These are developer tools; users only need the installer. CMake retrieves [miniz 3.1.0](https://github.com/richgel999/miniz/tree/174573d60290f447c13a2b1b3405de2b96e27d6c), pinned to its commit.

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

## License

MIT. The installer includes miniz's MIT license.
).Groups[1].Value
        if (-not $cleanZipHash -or (Get-FileHash -LiteralPath $cleanZipSetup -Algorithm SHA256).Hash -ne $cleanZipHash) { throw 'Clean Zip checksum verification failed.' }
        $cleanZipProcess = Start-Process -FilePath $cleanZipSetup -ArgumentList '/VERYSILENT','/SUPPRESSMSGBOXES','/NORESTART' -WindowStyle Hidden -Wait -PassThru
        if ($cleanZipProcess.ExitCode -ne 0) { throw "Clean Zip installation failed: $($cleanZipProcess.ExitCode)" }
        Write-Output 'Clean Zip installed.'
    } finally {
        if (Test-Path -LiteralPath $cleanZipSetup) { Remove-Item -LiteralPath $cleanZipSetup -Force }
    }
}
```

[Portable x64 ZIP](https://github.com/yusufkorkmaz/clean-zip-for-software-projects/releases/latest/download/CleanZip-Portable-x64.zip) · [Release notes and checksums](https://github.com/yusufkorkmaz/clean-zip-for-software-projects/releases/latest)

## Install and use

1. Download and run **CleanZip-Setup.exe** (about 2.2 MB).
2. Right-click a project folder or an empty area inside it, then choose **Clean Zip**.
3. Find `project.zip` beside `project`. The progress console closes automatically without a completion alert.

Installation is for your current Windows account. Administrator permission, .NET, Node.js, a Visual C++ redistributable and 7-Zip are not required. This release is **unsigned**, so Windows may show a SmartScreen warning.

## Where is Clean Zip?

| Computer | Menu in this unsigned release |
| --- | --- |
| Windows 7, 8, 8.1 or 10, x86/x64 | Classic right-click menu |
| Windows 11 x64, Developer Mode off | **Show more options > Clean Zip** |
| Windows 11 x64, Developer Mode already on | Modern menu if registration succeeds; otherwise **Show more options** |
| Windows on ARM | Classic menu through x86/x64 emulation; no native ARM64 extension |

**2.0.1 fixes duplicate entries:** when the modern command is available, setup hides the extra classic entry. Updates restore the classic entry when modern registration is unavailable.

Setup does not change your Windows menu preference, enable Developer Mode, import certificates or alter SmartScreen. A trusted signed identity package is needed to register the modern menu without Developer Mode ([Microsoft documentation](https://learn.microsoft.com/en-us/windows/apps/desktop/modernize/grant-identity-to-nonpackaged-apps)); this release does not include one.

Windows 7 and later are compatibility targets. Automated tests run on current Windows; installation on every older version and ARM has not been verified in separate VMs.

## Common situations

| Situation | What to do |
| --- | --- |
| **Windows protected your PC / Unknown publisher** | Verify the release checksum, then choose **More info > Run anyway** if offered. Turkish: **Ek bilgi > Yine de çalıştır**. |
| **Run anyway** is missing | A Windows policy can block continuing. See the policy steps below; on a managed computer, ask IT. |
| Windows 11 still opens the classic menu | A previous Windows customization can force it. Setup preserves this preference. See the restore steps below. |
| Two **Clean Zip** entries | Install **2.0.1 or later**, then restart File Explorer if the old menu is still cached. |
| The console closes without an alert | Expected behavior. Check for the ZIP beside the source folder. |
| No new ZIP appears | All files may be excluded, or the destination may be unwritable/in use. Run the command below in PowerShell to see the result or error. |

Verify the installer against `SHA256SUMS.txt` from the same release:

```powershell
Get-FileHash .\CleanZip-Setup.exe -Algorithm SHA256
```

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

## What is excluded?

| Content | Examples |
| --- | --- |
| Dependencies, build output and caches | `node_modules`, `.next`, `bin`, `obj`, `dist`, `.git`, virtual environments |
| Compiled files | `.dll`, `.exe`, `.pdb`, `.class`, `.pyc` |
| Media, fonts and archives | Images, videos, audio, PDF, ZIP, fonts |
| Office and design files | PowerPoint, Word, Excel, PSD, AI, XD, Sketch |
| Installers, disk files, database data and model weights | MSI, ISO, DB, MDF, ONNX, PT |
| Generated and temporary files | `.min.js`, `.min.css`, source maps, logs, dumps, temp files |

Ordinary JS/CSS and other source code, manifests, lockfiles, SQL schemas and configuration are kept. **`.env` files are kept too**; review secrets before sharing. This is a source-review ZIP: excluded images and other assets may be needed to run the complete application.

See [the full default exclusion list](CleanZip.rules.txt). Customize `%LOCALAPPDATA%\CleanZip\CleanZip.rules.txt`:

```text
d:node_modules
e:.pdf
s:.min.js
f:Thumbs.db
```

Rules ignore letter case: `d:` directory name at any depth, `e:` extension, `s:` filename suffix, `f:` exact filename. Excluded folders are skipped before scanning; links/reparse points are skipped.

## Update, uninstall and ZIP behavior

Run the latest installer to update. Uninstall from **Installed apps > Clean Zip** or the Start menu shortcut. Custom exclusion rules survive both updates and uninstallation.

Source files are never modified. UTF-8 filenames and ZIP64 are supported. An existing ZIP is replaced only after the new ZIP is complete; a failed run preserves the previous ZIP. An empty selection creates no ZIP.

## Command line

```powershell
& "$env:LOCALAPPDATA\CleanZip\CleanZip.exe" --path "C:\Projects\My Project" --no-ui
```

<details>
<summary>Preview selected files or choose another output</summary>

```powershell
CleanZip.exe --path "C:\Projects\My Project" --scan-only --manifest "C:\Temp\selected.txt"
CleanZip.exe --path "C:\Projects\My Project" --output "C:\Archives\source.zip" --no-ui
```

Use these commands from the executable's folder. Output and manifest paths must be outside the source folder.

</details>

<details>
<summary>Build and test for developers</summary>

Build requirements: Visual Studio C++ tools, Windows SDK, CMake 3.24+, Git, and Inno Setup 6.3+ for the installer. These are developer tools; users only need the installer. CMake retrieves [miniz 3.1.0](https://github.com/richgel999/miniz/tree/174573d60290f447c13a2b1b3405de2b96e27d6c), pinned to its commit.

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

## License

MIT. The installer includes miniz's MIT license.
