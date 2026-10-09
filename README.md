# Clean Zip for Software Projects

Right-click a Windows project folder and choose **Clean Zip** to create a source ZIP next to it. Dependencies, build output, binary files, media, Office documents and minified JS/CSS are excluded before compression.

## Installation

**[Download CleanZip-Setup.exe for Windows](https://github.com/yusufkorkmaz/clean-zip-for-software-projects/releases/latest/download/CleanZip-Setup.exe)** (approximately 2.2 MB)

[Portable x64 ZIP](https://github.com/yusufkorkmaz/clean-zip-for-software-projects/releases/latest/download/CleanZip-Portable-x64.zip) | [Release notes and SHA256 checksums](https://github.com/yusufkorkmaz/clean-zip-for-software-projects/releases/latest)

This first release is **unsigned**; Windows may show an unknown-publisher/SmartScreen warning. On Windows 11 without Developer Mode, Clean Zip appears under **Show more options**. The download is a working per-user installer, not a source archive.

The installer runs for the current user without administrator permissions. No .NET runtime, Node.js, Visual C++ redistributable or 7-Zip installation is required. The native ZIP writer and C++ runtime are linked into the executable.

| Windows | Context menu |
| --- | --- |
| Windows 7, 8, 8.1, 10, x86/x64 | Classic **Clean Zip** entry |
| Windows 11 x64, unsigned package | **Show more options**, plus the modern menu if Developer Mode is already enabled |
| Windows 11 x64, trusted signed identity package | Modern **Clean Zip** entry plus the classic fallback |
| Windows on ARM | Classic entry through Windows' x86/x64 emulation; no native ARM64 shell extension |

The installer never enables Developer Mode or imports a trust certificate. Windows 11's modern Explorer integration needs package identity: production registration requires a trusted signed MSIX identity package; the unsigned source-build path needs existing Developer Mode. See [Microsoft's package identity documentation](https://learn.microsoft.com/en-us/windows/apps/desktop/modernize/grant-identity-to-nonpackaged-apps).

The compatibility target is Windows 7 and later. Automated build, archive and installer tests run on current Windows; Explorer installation on every older Windows version has not been tested in separate VMs.

### SmartScreen warning during installation

This release has no digital signature, so Windows may display **Windows protected your PC** and **Unknown publisher**. Download from the release link above and verify the file against `SHA256SUMS.txt` from the same release:

```powershell
Get-FileHash .\CleanZip-Setup.exe -Algorithm SHA256
```

If you trust the verified download and Windows offers it, select **More info > Run anyway** (**Ek bilgi > Yine de çalıştır** in Turkish).

If **Run anyway** is missing, a SmartScreen policy can prevent users from continuing. An administrator can inspect the policy on editions with Local Group Policy Editor:

1. Press **Win + R**, enter `gpedit.msc`, and press Enter.
2. Open **Computer Configuration > Administrative Templates > Windows Components > Windows Defender SmartScreen > Explorer**.
3. Open **Configure Windows Defender SmartScreen**.

On a personal computer you own and administer, **Enabled > Warn** allows the confirmation while keeping SmartScreen warnings enabled; **Warn and prevent bypass** removes that option. This changes override behavior for all downloaded applications. On a managed work/school computer, ask IT for an approved installation instead of changing the organization's policy.

Turkish path: **Bilgisayar Yapılandırması > Yönetim Şablonları > Windows Bileşenleri > Windows Defender SmartScreen > Gezgin > Windows Defender SmartScreen'i yapılandır**; the choices are **Etkin > Uyar** and **Uyar ve geçişleri engelle**.

Clean Zip does not change SmartScreen policies. A valid signing certificate can still require reputation before warnings disappear. See Microsoft's [SmartScreen policy documentation](https://learn.microsoft.com/en-us/windows/client-management/mdm/policy-csp-smartscreen#preventoverrideforfilesinshell) and [app reputation documentation](https://learn.microsoft.com/en-us/windows/apps/package-and-deploy/smartscreen-reputation).

## Use

1. Install Clean Zip.
2. Right-click a project folder, or an empty area inside it, and choose **Clean Zip**.
3. Find `project.zip` next to `project`.

The console shows progress, then closes without a completion alert. Excluded folders are never entered, reparse points are skipped, and files are streamed into a ZIP64 archive using fast Deflate compression. ZIP filenames use UTF-8, including Turkish characters. An existing output is replaced only after the new archive is complete; a failed run leaves the old ZIP intact.

## Exclusion rules

Edit `%LOCALAPPDATA%\CleanZip\CleanZip.rules.txt`. Existing rules survive updates and uninstallation.

```text
d:node_modules
d:.next
d:bin
d:obj
e:.dll
e:.pdf
e:.pptx
s:.min.js
s:.min.css
f:Thumbs.db
```

Rules match case-insensitively. `d:` skips an exact directory name at any depth; `e:` excludes a file extension; `s:` excludes a filename suffix; `f:` excludes an exact filename. Versioned `.so.*` files are also excluded. Ordinary source JS/CSS, project manifests, lockfiles, SQL schemas, configuration and hidden source files are kept. `.env` files are retained: review the selected source before sharing a ZIP if a project contains credentials.

## Command line

```powershell
CleanZip.exe --path "C:\Projects\My Project" --no-ui
CleanZip.exe --path "C:\Projects\My Project" --scan-only --manifest "C:\Temp\selected.txt"
CleanZip.exe --path "C:\Projects\My Project" --output "C:\Archives\source.zip" --no-ui
```

Output and manifest paths must be outside the source folder. An empty selection does not create a ZIP. Files and folders in the source are never modified.

## Build and test

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

Uninstall from Windows **Installed apps > Clean Zip**, or the Start menu shortcut. User exclusion rules are retained.

## License

MIT. The installer includes miniz's MIT license.
