# Clean Zip for Software Projects

Fast Windows right-click utility for zipping software projects with configurable exclusions for dependencies, build artifacts, media, documents, and minified JS/CSS files.

## Features

- Adds **Clean Zip** to the context menu of a folder and its background.
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
2. Select **Clean Zip**. On Windows 11, use **Show more options** if necessary.
3. Find the ZIP next to the selected folder: `my-project` becomes `my-project.zip`.

The console shows progress and closes when the process exits. A single folder is handled per invocation.

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
```

Tests create temporary fixtures under `build`, verify exact ZIP contents and file data, and cover nested exclusions, uppercase extensions, minified suffixes, hidden files, Unicode, spaces, and special filename characters. GitHub Actions builds and tests on Windows and provides a portable build artifact.

## Uninstall

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\Uninstall-CleanZip.ps1
```

For a custom installation folder, pass the same `-InstallationDirectory` used at installation. The uninstaller removes the context-menu entries belonging to that installation. Remove the installation folder manually to also remove its files and backups.
