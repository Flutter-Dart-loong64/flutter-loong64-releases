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
flutter_base="$(basename "$flutter_root")"
flutter_archive_root="${FLUTTER_ARCHIVE_ROOT:-flutter}"

mkdir -p "$output_dir"

dart_commit="$(git -C "$dart_root" rev-parse --short=12 HEAD)"
flutter_commit="$(git -C "$flutter_root" rev-parse --short=12 HEAD)"
engine_commit="$(git -C "$engine_src/flutter" rev-parse --short=12 HEAD)"
xz_cmd="${XZ_CMD:-xz -T0 -6}"

engine_staging="$(mktemp -d)"
trap 'rm -rf "$engine_staging"' EXIT

engine_entries=(libflutter_linux_gtk.so gen_snapshot flutter_linux)
for required_entry in "${engine_entries[@]}"; do
  cp -a "$engine_out/$required_entry" "$engine_staging/"
done

if [[ -e "$engine_out/icudtl.dat" ]]; then
  cp -a "$engine_out/icudtl.dat" "$engine_staging/"
elif [[ -e "$flutter_root/bin/cache/artifacts/engine/linux-loong64/icudtl.dat" ]]; then
  cp -a "$flutter_root/bin/cache/artifacts/engine/linux-loong64/icudtl.dat" "$engine_staging/"
else
  echo "missing icudtl.dat in $engine_out or linux-loong64 cache" >&2
  exit 1
fi
engine_entries+=(icudtl.dat)

for optional_entry in impellerc font-subset LICENSE.flutter_gtk.md shader_lib; do
  if [[ -e "$engine_out/$optional_entry" ]]; then
    cp -a "$engine_out/$optional_entry" "$engine_staging/"
    engine_entries+=("$optional_entry")
  fi
done

tar -C "$dart_root/out/ReleaseLOONG64" \
  -I "$xz_cmd" \
  -cf "$output_dir/dart-sdk-linux-loong64-${release_id}-${dart_commit}.tar.xz" \
  dart-sdk

tar -C "$engine_staging" \
  -I "$xz_cmd" \
  -cf "$output_dir/flutter-engine-linux-loong64-gtk-${release_id}-${engine_commit}.tar.xz" \
  "${engine_entries[@]}"

tar -C "$(dirname "$flutter_root")" \
  --exclude="$flutter_base/.gclient" \
  --exclude="$flutter_base/.gclient_entries" \
  --exclude="$flutter_base/.dart_tool" \
  --exclude="$flutter_base/**/.dart_tool" \
  --exclude="$flutter_base/engine/src" \
  --exclude="$flutter_base/third_party" \
  --exclude="$flutter_base/bin/cache/downloads" \
  --exclude="$flutter_base/bin/cache/dart-sdk.old" \
  --exclude="$flutter_base/bin/cache/artifacts/material_fonts" \
  --exclude="$flutter_base/bin/cache/artifacts/engine/linux-loong64-release/backup-before-*" \
  --exclude="$flutter_base/bin/cache/artifacts/engine/linux-loong64-release/gen_snapshot.15f-backup" \
  --exclude="$flutter_base/**/build" \
  --transform="s#^$flutter_base#$flutter_archive_root#" \
  -I "$xz_cmd" \
  -cf "$output_dir/flutter-sdk-linux-loong64-${release_id}-${flutter_commit}.tar.xz" \
  "$flutter_base"

(
  cd "$output_dir"
  sha256sum *.tar.xz > SHA256SUMS
)
