# Clean Zip for Software Projects

Fast Windows right-click utility for zipping software projects with configurable exclusions for dependencies, build artifacts, media, documents, and minified JS/CSS files.

## Features

- Adds **Clean Zip** to the context menu of a folder and its background.
- Optional Windows 11 integration shows **Clean Zip** directly in the modern menu.
- Skips excluded directories before scanning their contents.
- Uses a compiled C# scanner and optional 7-Zip compression.
- Falls back to .NET ZIP compression when 7-Zip is unavailable.
- Keeps relative paths and Unicode filenames.
- Replaces an existing ZIP only after the new archive finishes successfully.
- Closes the command window automatically, without a completion alert.
- Installs for the current user; administrator rights are not required.

## Requirements

- Windows with .NET Framework 4.5 or later and its C# compiler.
- Windows PowerShell or PowerShell on Windows for build and installation.
- Optional: 7-Zip installed in the standard `Program Files\7-Zip` directory.

## Install

Download this repository using **Code > Download ZIP**, extract it, and open PowerShell in the extracted folder:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\Install-CleanZip.ps1
```

The installer builds the executable and installs it into `%LOCALAPPDATA%\CleanZip`. It backs up existing files and context-menu settings before updating them. Existing installed exclusion rules are preserved; use `-ResetRules` to replace them with the repository defaults.

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\Install-CleanZip.ps1 -ResetRules
```

To use a custom installation folder:

```powershell
.\Install-CleanZip.ps1 -InstallationDirectory 'D:\Tools\CleanZip'
```

## Use

1. Right-click a software project folder or an empty area inside it.
2. Select **Clean Zip**. The modern-menu installation below displays it directly on Windows 11; the basic installer uses **Show more options**.
3. Find the ZIP next to the selected folder: `my-project` becomes `my-project.zip`.

The console shows progress and closes when the process exits. A single folder is handled per invocation.

## Windows 11 modern context menu

For x64 Windows 11, install the basic utility first, then run:

```powershell
.\Install-ModernMenu.ps1
```

The modern extension requires the **.NET 10 x64 SDK** to build and the **.NET 10 x64 runtime** on the installed computer. This source-build installer registers an unpackaged application identity using `Add-AppxPackage -Register -ExternalLocation`, which requires **Developer Mode** already enabled. The installer does not enable Developer Mode or install certificates. The normal installer remains available without these additional requirements.

If an old registry tweak forces the classic context menu, explicitly restore the native Windows 11 menu while installing:

```powershell
.\Install-ModernMenu.ps1 -RestoreWindows11Menu
```

Pass the same `-InstallationDirectory` to both installers when using a custom folder. Restart File Explorer after installation to reload the command. Existing exclusion rules are reused. The optional restore switch backs up and removes only the per-user `{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}` classic-menu override.

The extension uses `IExplorerCommand` with packaged COM activation in a Windows surrogate process. It only inspects the selected folder or current folder view when opening the menu; scanning and compression begin after selection. Each update uses a separate extension directory so a loaded DLL can finish safely. Old extension directories and backups remain until removed manually. Distribution without Developer Mode requires a signed package; this repository currently supplies a development registration, not a signed MSIX release. See [Microsoft's Explorer integration documentation](https://learn.microsoft.com/en-us/windows/apps/desktop/modernize/integrate-packaged-app-with-file-explorer).

These archives are intended for source-code inspection. The default exclusions omit dependencies, binary assets, and data that can be required to run an application. Source and configuration files, including environment files, are included unless an exclusion rule matches them.

## Exclusion rules

Edit `%LOCALAPPDATA%\CleanZip\CleanZip.rules.txt` after installation. Rules are case-insensitive and apply at every directory depth:

| Prefix | Matches | Example |
| --- | --- | --- |
| `d:` | Exact directory name; skips the entire directory | `d:node_modules` |
| `e:` | File extension | `e:.pptx` |
| `f:` | Exact filename | `f:.env.local` |
| `s:` | Filename suffix | `s:.min.js` |

Lines starting with `#` are comments. Filename suffixes are literal, so use `s:.min.js`, rather than a wildcard. Normal `.js` and `.css` files remain included.

Defaults cover:

- `node_modules`, `.next`, `bin`, `obj`, `.git`, build output, caches, and virtual environments.
- Compiled binaries, debug symbols, logs, and temporary files.
- Images, videos, audio, PDFs, fonts, and existing archives.
- Office documents, design files, installers, disk images, databases, and model weights.
- `*.min.js` and `*.min.css`.

See [CleanZip.rules.txt](CleanZip.rules.txt) for the complete list. Reparse points, including symbolic links and directory junctions, are skipped. Filtering uses file names and extensions; it does not inspect the contents of binary files with custom extensions.

## Build and command line

```powershell
.\Build-CleanZip.ps1
.\build\CleanZip.exe --path 'D:\Projects\my-project' --no-ui
```

Preview the selected files without creating a ZIP:

```powershell
.\build\CleanZip.exe --path 'D:\Projects\my-project' --scan-only
```

Export the selected relative paths:

```powershell
.\build\CleanZip.exe --path 'D:\Projects\my-project' --scan-only --manifest '.\selected-files.txt'
```

Choose an output location outside the source folder:

```powershell
.\build\CleanZip.exe --path 'D:\Projects\my-project' --no-ui --output 'D:\Archives\review.zip'
```

The `build` folder contains the executable, PowerShell wrapper, and rules file. Keep these three files together when using a portable build.

## Test

```powershell
.\Build-CleanZip.ps1
.\tests\Test-CleanZip.ps1
.\Build-ModernMenu.ps1
dotnet run --project .\tests\ShellTests\ShellTests.csproj -c Release
```

Tests create temporary fixtures under `build`, verify exact ZIP contents and file data, and cover nested exclusions, uppercase extensions, minified suffixes, hidden files, Unicode, spaces, and special filename characters. GitHub Actions builds and tests on Windows and provides a portable build artifact.

The shell tests verify the title and actual Windows folder/file selections. After installing the modern menu, add `-- --installed` to the `dotnet run` command to also verify out-of-process COM activation and end-to-end invocation with ZIP-content checks.

## Uninstall

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\Uninstall-CleanZip.ps1
```

For a custom installation folder, pass the same `-InstallationDirectory` used at installation. The uninstaller removes the context-menu entries belonging to that installation. Remove the installation folder manually to also remove its files and backups.
