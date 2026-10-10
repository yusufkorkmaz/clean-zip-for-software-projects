# Clean Zip — For Mac

[Türkçe](README.tr.md)

Create source-code ZIPs on Apple Silicon Mac. No Python, Node.js, .NET or 7-Zip installation is needed.

## Install and use

1. [Download the Mac package](https://github.com/yusufkorkmaz/clean-zip-for-software-projects/releases/download/v2.0.1-macos.1/CleanZip-macOS-AppleSilicon.zip), extract the ZIP and run `Install.command` inside it.
2. In Finder, right-click a project folder → **Quick Actions**.
3. If Clean Zip is missing, choose **Customize…** and turn on the **Clean Zip** switch.
4. Close settings, right-click the project folder again → **Quick Actions → Clean Zip**.
5. Find the ZIP beside the folder: `project` → `project.zip`.

Clean Zip lives inside **Quick Actions**. Select multiple folders to create a separate ZIP for each. There is no completion notification; check beside the folder. Automator displays an error if the action fails.

## Install and use with Terminal

Open Terminal and paste the entire installation block. It downloads the Mac package, verifies SHA-256, extracts it and installs or updates for your account. Administrator rights are not required.

### Install or update

```bash
/bin/bash <<'CLEANZIP'
set -euo pipefail
cleanzip_release="https://github.com/yusufkorkmaz/clean-zip-for-software-projects/releases/download/v2.0.1-macos.1"
cleanzip_dir=$(mktemp -d "${TMPDIR:-/tmp}/cleanzip.XXXXXX")
trap 'rm -rf "$cleanzip_dir"' EXIT
cd "$cleanzip_dir"
/usr/bin/curl -fL --retry 2 "$cleanzip_release/CleanZip-macOS-AppleSilicon.zip" -o CleanZip-macOS-AppleSilicon.zip
/usr/bin/curl -fL --retry 2 "$cleanzip_release/SHA256SUMS.txt" -o SHA256SUMS.txt
/usr/bin/awk '$2 == "CleanZip-macOS-AppleSilicon.zip" { print }' SHA256SUMS.txt > package.sha256
test -s package.sha256
/usr/bin/shasum -a 256 -c package.sha256
/usr/bin/ditto -x -k CleanZip-macOS-AppleSilicon.zip extracted
/bin/bash "extracted/CleanZip-macOS/Install.command"
CLEANZIP
```

After installation, use **Finder → right-click a project folder → Quick Actions → Clean Zip**. If it is missing, open **Quick Actions → Customize…** and turn on the **Clean Zip** switch.

### Create a ZIP and other commands

Replace `cleanzip_project` below with your own project folder. These examples cover version, help, ZIP creation, file preview, a different output and custom rules.

```bash
cleanzip_engine="$HOME/Library/Application Support/CleanZip/CleanZip"
cleanzip_project="$HOME/Projects/My Project"
cleanzip_archives="$HOME/CleanZip-Archives"
mkdir -p "$cleanzip_archives"

# Show the installed version and available options.
"$cleanzip_engine" --version
"$cleanzip_engine" --help

# Create a ZIP beside the project folder.
"$cleanzip_engine" --path "$cleanzip_project" --no-ui

# Preview the selected files without creating a ZIP.
"$cleanzip_engine" --path "$cleanzip_project" --scan-only --manifest "$cleanzip_archives/selected.txt"

# Write the ZIP to another folder.
"$cleanzip_engine" --path "$cleanzip_project" --output "$cleanzip_archives/project.zip" --no-ui

# Use another rules file (edit the copy first).
cp "$HOME/Library/Application Support/CleanZip/CleanZip.rules.txt" "$cleanzip_archives/custom.rules.txt"
"$cleanzip_engine" --path "$cleanzip_project" --rules "$cleanzip_archives/custom.rules.txt" --output "$cleanzip_archives/custom.zip"
```

The destination folder must exist. ZIP and manifest targets must be outside the project and different from each other. UTF-8 filenames and ZIP64 are supported. The target is replaced atomically after the new ZIP is flushed to disk. File permissions and extended attributes are not stored; this is not a complete project backup.

## What goes in the ZIP?

Source code and configuration are kept; dependencies, build output, caches, media and common binary files are excluded. [Full rules](../CleanZip.rules.txt).

**`.env` files are included; check for secrets before sharing.** `.gitignore` is not applied automatically. The ZIP is for code review; excluded files may be needed to run the project.

Source files stay unchanged. Links and special files are skipped. The old ZIP is replaced only after the new archive is complete; errors and empty selections preserve it.

<details>
<summary>Update, remove or customize rules</summary>

Installation is for your current account; administrator rights are not required. The app and rules live in `~/Library/Application Support/CleanZip`; the Quick Action lives in `~/Library/Services/Clean Zip.workflow`.

Run `Install.command` from a new package to update. Custom rules are preserved; the previous app and action are saved in `Backups`.

Edit the installed `CleanZip.rules.txt` to customize exclusions: `d:` folder, `e:` extension, `s:` filename suffix, `f:` exact filename. Rules ignore case.

To remove, use Finder → **Go → Go to Folder** to open `~/Library/Services`, then delete `Clean Zip.workflow`. Remove `~/Library/Application Support/CleanZip` as well; save your custom rules first if needed.

</details>

<details>
<summary>Developers and compatibility</summary>

With Xcode Command Line Tools and Git, run from the repository root:

```bash
bash macos/Build.sh
python3 tests/Test-Mac.py build/macos/CleanZip
python3 macos/Package.py /path/to/package
```

miniz is pinned to a specific commit. CMake builds are also supported.

The target is macOS 12+. The Apple Silicon build was verified on this MacBook; Intel and older macOS versions have not been tested on separate devices. The package is locally ad hoc signed, without Developer ID signing or Apple notarization.

</details>

MIT license. The package includes miniz's MIT license.
