# Clean Zip 2.0.1

Download **CleanZip-Setup.exe** and install it for your Windows user account. The installer is approximately 2.2 MB.

- Fix duplicate **Clean Zip** entries: when modern registration succeeds, the static classic fallback is hidden. Explorer's packaged command remains available in both menus.
- Restore the classic fallback on updates when modern registration is unavailable, including stale hidden entries from previous installations.
- Preserve the user's Windows context-menu preferences; setup does not switch Windows between modern and classic menus.

- Native C++ scanner, ZIP writer and Explorer command: no .NET runtime or Visual C++ redistributable required.
- Fast directory pruning with the existing source-only rules, including `.next`, `node_modules`, `bin`, `obj`, binary/media/document files and minified JS/CSS.
- Single installer with x86/x64 engines, preserved custom rules and an uninstaller.
- Progress console closes automatically without a completion alert.
- UTF-8 ZIP paths, ZIP64 support, and preservation of the previous ZIP if a run fails.

**Signing:** this release is unsigned. Windows may show an unknown-publisher or SmartScreen warning. Windows 11 normally displays Clean Zip under **Show more options**; on x64 computers with Developer Mode already enabled, the installer also registers the native modern menu. The installer does not change Developer Mode or certificate trust. A trusted signed identity package is needed for ordinary production installation of the modern menu.

Automated checks cover x86/x64 archive and COM behavior, setup, menu visibility migration, silent update, rule preservation and uninstallation. The ZIP engine is unchanged from 2.0.0.

The compatibility target is Windows 7 and later; complete installation on every older Windows version has not been verified in separate VMs. ARM uses the classic menu through Windows emulation.

`SHA256SUMS.txt` contains checksums for the installer and portable x64 ZIP.
