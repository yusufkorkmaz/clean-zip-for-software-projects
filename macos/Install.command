#!/bin/bash
set -euo pipefail
task_package=$(cd "$(dirname "$0")" && pwd)
task_install="$HOME/Library/Application Support/CleanZip"
task_services="$HOME/Library/Services"
while [ $# -gt 0 ]; do
  case "$1" in
    --prefix) task_install="$2"; shift 2 ;;
    --services) task_services="$2"; shift 2 ;;
    *) echo "Unknown argument: $1" >&2; exit 1 ;;
  esac
done
"$task_package/CleanZip" --version
mkdir -p "$task_install" "$task_services"
task_backup="$task_install/Backups/$(date +%Y%m%d-%H%M%S)-$$"
if [ -f "$task_install/CleanZip" ] || [ -d "$task_services/Clean Zip.workflow" ]; then
  mkdir -p "$task_backup"
  [ ! -f "$task_install/CleanZip" ] || cp -p "$task_install/CleanZip" "$task_backup/CleanZip"
  [ ! -d "$task_services/Clean Zip.workflow" ] || ditto "$task_services/Clean Zip.workflow" "$task_backup/Clean Zip.workflow"
fi
task_stage=$(mktemp "$task_install/CleanZip.XXXXXX")
trap 'rm -f "$task_stage"' EXIT
cp "$task_package/CleanZip" "$task_stage"
chmod 755 "$task_stage"
mv -f "$task_stage" "$task_install/CleanZip"
if [ ! -f "$task_install/CleanZip.rules.txt" ]; then
  cp "$task_package/CleanZip.rules.txt" "$task_install/CleanZip.rules.txt"
fi
cp "$task_package/LICENSE" "$task_install/LICENSE"
cp "$task_package/miniz-LICENSE.txt" "$task_install/miniz-LICENSE.txt"
ditto "$task_package/Clean Zip.workflow" "$task_services/Clean Zip.workflow"
/System/Library/CoreServices/pbs -read_bundle "$task_services/Clean Zip.workflow" >/dev/null 2>&1
/System/Library/CoreServices/pbs -update >/dev/null 2>&1
echo 'Kuruldu. Finder: klasöre sağ tık → Hızlı Eylemler → Clean Zip.'
echo "Kurallar: $task_install/CleanZip.rules.txt"
