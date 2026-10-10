# Clean Zip — For Mac

[Türkçe](README.tr.md)

Create source-code ZIPs on Apple Silicon Mac. No Python, Node.js, .NET or 7-Zip installation is needed.

## Install and use

1. [Download the Mac package](https://github.com/yusufkorkmaz/clean-zip-for-software-projects/releases/download/v2.0.1-macos.1/CleanZip-macOS-AppleSilicon.zip), extract the ZIP and run `Install.command` inside it.
2. In Finder, right-click a project folder → **Quick Actions**.
3. If Clean Zip is missing, choose **Customize…** and turn on the **Clean Zip** switch.
4. Return to the menu → **Quick Actions → Clean Zip**.
5. Find the ZIP beside the folder: `project` → `project.zip`.

Clean Zip lives inside **Quick Actions**. Select multiple folders to create a separate ZIP for each. There is no completion notification; check beside the folder. Automator displays an error if the action fails.

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
<summary>Command line and archive details</summary>

```bash
"$HOME/Library/Application Support/CleanZip/CleanZip" --path "/path/to/project"
"$HOME/Library/Application Support/CleanZip/CleanZip" --path "/path/to/project" --scan-only --manifest "/tmp/selected.txt"
"$HOME/Library/Application Support/CleanZip/CleanZip" --path "/path/to/project" --output "/archives/project.zip"
```

The destination folder must exist. ZIP and manifest targets must be outside the project and different from each other. UTF-8 filenames and ZIP64 are supported. The target is replaced atomically after the new ZIP is flushed to disk. File permissions and extended attributes are not stored; this is not a complete project backup.

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
