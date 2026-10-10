#!/bin/bash
set -euo pipefail
task_repo=$(cd "$(dirname "$0")/.." && pwd)
task_build="$task_repo/build/macos"
task_miniz=${MINIZ_SOURCE:-"$task_build/miniz-src"}
task_revision=174573d60290f447c13a2b1b3405de2b96e27d6c
mkdir -p "$task_build/objects"
if [ ! -d "$task_miniz" ]; then
  git clone https://github.com/richgel999/miniz.git "$task_miniz"
  git -C "$task_miniz" checkout --detach "$task_revision"
fi
if [ "$(git -C "$task_miniz" rev-parse HEAD)" != "$task_revision" ]; then
  echo 'miniz must be at the pinned revision.' >&2
  exit 1
fi
printf '#pragma once\n#define MINIZ_EXPORT\n' > "$task_build/miniz_export.h"
for task_file in miniz miniz_tdef miniz_tinfl miniz_zip; do
  xcrun clang -O2 -mmacosx-version-min=12.0 -I "$task_miniz" -I "$task_build" \
    -c "$task_miniz/$task_file.c" -o "$task_build/objects/$task_file.o"
done
xcrun clang++ -std=c++17 -O2 -Wall -Wextra -Wpedantic -mmacosx-version-min=12.0 \
  -I "$task_miniz" -I "$task_build" "$task_repo/native/CleanZipMac.cpp" \
  "$task_build/objects/"*.o -framework CoreFoundation -o "$task_build/CleanZip"
cp "$task_repo/CleanZip.rules.txt" "$task_build/CleanZip.rules.txt"
codesign --force --sign - "$task_build/CleanZip"
"$task_build/CleanZip" --version
echo "Built: $task_build/CleanZip"
