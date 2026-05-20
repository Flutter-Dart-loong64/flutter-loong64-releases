#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 2 ]]; then
  echo "usage: $0 <release-id> <output-dir>" >&2
  exit 2
fi

release_id="$1"
output_dir="$2"

: "${FLUTTER_ROOT:?Set FLUTTER_ROOT to the Flutter SDK checkout path.}"
: "${DART_ROOT:?Set DART_ROOT to the Dart SDK checkout path.}"
: "${ENGINE_SRC:?Set ENGINE_SRC to the Flutter Engine source root.}"

flutter_root="$FLUTTER_ROOT"
dart_root="$DART_ROOT"
engine_src="$ENGINE_SRC"
engine_out="${ENGINE_OUT:-$flutter_root/bin/cache/artifacts/engine/linux-loong64-release}"

mkdir -p "$output_dir"

dart_commit="$(git -C "$dart_root" rev-parse --short=12 HEAD)"
flutter_commit="$(git -C "$flutter_root" rev-parse --short=12 HEAD)"
engine_commit="$(git -C "$engine_src/flutter" rev-parse --short=12 HEAD)"
xz_cmd="${XZ_CMD:-xz -T0 -6}"

engine_entries=(libflutter_linux_gtk.so gen_snapshot icudtl.dat flutter_linux)
for optional_entry in impellerc font-subset LICENSE.flutter_gtk.md shader_lib; do
  if [[ -e "$engine_out/$optional_entry" ]]; then
    engine_entries+=("$optional_entry")
  fi
done

tar -C "$dart_root/out/ReleaseLOONG64" \
  -I "$xz_cmd" \
  -cf "$output_dir/dart-sdk-linux-loong64-${release_id}-${dart_commit}.tar.xz" \
  dart-sdk

tar -C "$engine_out" \
  -I "$xz_cmd" \
  -cf "$output_dir/flutter-engine-linux-loong64-gtk-${release_id}-${engine_commit}.tar.xz" \
  "${engine_entries[@]}"

tar -C "$(dirname "$flutter_root")" \
  --exclude='flutter/.git' \
  --exclude='flutter/.dart_tool' \
  --exclude='flutter/**/.dart_tool' \
  --exclude='flutter/bin/cache/pkg' \
  --exclude='flutter/bin/cache/downloads' \
  --exclude='flutter/bin/cache/dart-sdk.old' \
  --exclude='flutter/bin/cache/artifacts/material_fonts' \
  --exclude='flutter/bin/cache/artifacts/engine/linux-loong64-release/backup-before-*' \
  --exclude='flutter/bin/cache/artifacts/engine/linux-loong64-release/gen_snapshot.15f-backup' \
  --exclude='flutter/**/build' \
  -I "$xz_cmd" \
  -cf "$output_dir/flutter-sdk-linux-loong64-${release_id}-${flutter_commit}.tar.xz" \
  "$(basename "$flutter_root")"

(
  cd "$output_dir"
  sha256sum *.tar.xz > SHA256SUMS
)
