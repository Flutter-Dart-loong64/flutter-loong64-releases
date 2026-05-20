#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 2 ]]; then
  echo "usage: $0 <release-id> <output-dir>" >&2
  exit 2
fi

release_id="$1"
output_dir="$2"

flutter_root="${FLUTTER_ROOT:-$HOME/Flutter/flutter}"
dart_root="${DART_ROOT:-$HOME/Flutter/dart-sdk}"
engine_src="${ENGINE_SRC:-$HOME/Flutter/engine/src}"
engine_out="${ENGINE_OUT:-$engine_src/out/linux_release_loong64_gtk}"

mkdir -p "$output_dir"

dart_commit="$(git -C "$dart_root" rev-parse --short=12 HEAD)"
flutter_commit="$(git -C "$flutter_root" rev-parse --short=12 HEAD)"
engine_commit="$(git -C "$engine_src/flutter" rev-parse --short=12 HEAD)"

tar -C "$dart_root/out/ReleaseLOONG64" \
  -cJf "$output_dir/dart-sdk-linux-loong64-${release_id}-${dart_commit}.tar.xz" \
  dart-sdk

tar -C "$engine_out" \
  -cJf "$output_dir/flutter-engine-linux-loong64-gtk-${release_id}-${engine_commit}.tar.xz" \
  libflutter_linux_gtk.so gen_snapshot

tar -C "$(dirname "$flutter_root")" \
  --exclude='flutter/.git' \
  --exclude='flutter/bin/cache/pkg' \
  --exclude='flutter/bin/cache/downloads' \
  --exclude='flutter/bin/cache/artifacts/material_fonts' \
  -cJf "$output_dir/flutter-sdk-linux-loong64-${release_id}-${flutter_commit}.tar.xz" \
  "$(basename "$flutter_root")"

(
  cd "$output_dir"
  sha256sum *.tar.xz > SHA256SUMS
)
