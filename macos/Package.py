#!/usr/bin/env python3
"""Package an already-built native binary and a Finder Quick Action."""
import argparse
import plistlib
import shutil
from pathlib import Path

repo = Path(__file__).resolve().parent.parent
parser = argparse.ArgumentParser()
parser.add_argument("output", type=Path)
parser.add_argument("--miniz-source", type=Path, default=repo / "build/macos/miniz-src")
args = parser.parse_args()
package = args.output.resolve()
package.mkdir(parents=True, exist_ok=True)
for source, name in [(repo / "build/macos/CleanZip", "CleanZip"),
                     (repo / "CleanZip.rules.txt", "CleanZip.rules.txt"),
                     (repo / "LICENSE", "LICENSE"),
                     (args.miniz_source / "LICENSE", "miniz-LICENSE.txt"),
                     (repo / "macos/Install.command", "Install.command")]:
    shutil.copy2(source, package / name)
for name in ("README.md", "README.tr.md"):
    guide = (repo / "macos" / name).read_text()
    (package / name).write_text(guide.replace("../CleanZip.rules.txt", "CleanZip.rules.txt"))
(package / "Install.command").chmod(0o755)
contents = package / "Clean Zip.workflow/Contents"
contents.mkdir(parents=True, exist_ok=True)
script = '''set -eu
engine="$HOME/Library/Application Support/CleanZip/CleanZip"
for folder in "$@"; do
    if [ ! -d "$folder" ]; then
        echo "Lütfen bir proje klasörü seçin." >&2
        exit 1
    fi
    "$engine" --path "$folder" --no-ui
done
'''
action_info = plistlib.loads(Path("/System/Library/Automator/Run Shell Script.action/Contents/Info.plist").read_bytes())
action = {"ActionBundlePath": "/System/Library/Automator/Run Shell Script.action",
          "ActionName": "Run Shell Script", "ActionParameters": {
              "COMMAND_STRING": script, "CheckedForUserDefaultShell": True,
              "inputMethod": 1, "shell": "/bin/bash", "source": ""},
          "AMAccepts": action_info["AMAccepts"], "AMProvides": action_info["AMProvides"],
          "BundleIdentifier": "com.apple.RunShellScript", "CanShowWhenRun": True,
          "CanShowSelectedItemsWhenRun": False,
          "CFBundleVersion": action_info["CFBundleVersion"], "Class Name": "RunShellScriptAction",
          "InputUUID": "6E67C285-824D-4FAD-A5F4-B3F0B342D40D", "OutputUUID": "138AE9DE-5D6E-419A-BBC3-B2057B7F11A8",
          "UUID": "C0E0B478-95BE-4BF1-A117-C0AFA611FF80", "isViewVisible": True}
document = {"AMDocumentVersion": "2", "actions": [{"action": action, "isRunAfterAction": False}],
            "connectors": [], "workflowMetaData": {
                "workflowTypeIdentifier": "com.apple.Automator.servicesMenu",
                "applicationBundleID": "com.apple.finder",
                "applicationBundleIDsByPath": {"/System/Library/CoreServices/Finder.app": "com.apple.finder"},
                "applicationPath": "/System/Library/CoreServices/Finder.app",
                "applicationPaths": ["/System/Library/CoreServices/Finder.app"],
                "inputTypeIdentifier": "com.apple.Automator.fileSystemObject.folder",
                "outputTypeIdentifier": "com.apple.Automator.nothing",
                "presentationMode": 15,
                "processesInput": False,
                "systemImageName": "NSActionTemplate",
                "useAutomaticInputType": False,
                "serviceApplicationBundleID": "com.apple.finder",
                "serviceApplicationPath": "/System/Library/CoreServices/Finder.app",
                "serviceInputTypeIdentifier": "com.apple.Automator.fileSystemObject.folder",
                "serviceOutputTypeIdentifier": "com.apple.Automator.nothing",
                "serviceProcessesInput": False}}
info = {"CFBundleIdentifier": "dev.yusufkorkmaz.cleanzip.quickaction",
        "CFBundleName": "Clean Zip", "CFBundleShortVersionString": "2.0.1",
        "NSServices": [{"NSMenuItem": {"default": "Clean Zip"},
                        "NSIconName": "NSActionTemplate",
                        "NSBackgroundColorName": "background",
                        "NSMessage": "runWorkflowAsService",
                        "NSRequiredContext": {"NSApplicationIdentifier": "com.apple.finder"},
                        "NSSendFileTypes": ["public.folder"]}]}
for path, data in [(contents / "document.wflow", document), (contents / "Info.plist", info)]:
    path.write_bytes(plistlib.dumps(data))
print(package)
