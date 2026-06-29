# Building Loong64 Flutter From Source

This document describes the native LoongArch64/Loong64 build flow used for the release archives in this repository.

The expected build host is a native LoongArch64 UOS 25 or deepin 25 system. Cross-building the Linux desktop engine from x86_64 is not covered here.

## Source Repository Roles

The Loong64 source work is split across four forks under `Flutter-Dart-loong64`:

| Repository | Upstream | Build role |
| --- | --- | --- |
| [`flutter`](https://github.com/Flutter-Dart-loong64/flutter) | `flutter/flutter` | Main Flutter SDK checkout and release archive root. It contains Flutter tool changes for `linux-loong64`, host detection, cache artifact names, native asset integration, and the current `engine/src` checkout used by this build flow. |
| [`sdk`](https://github.com/Flutter-Dart-loong64/sdk) | `dart-lang/sdk` | Dart SDK and VM checkout. Build this first; its Loong64 `dart`, `gen_snapshot`, runtime, JIT/AOT backend, and snapshots must match the engine build revision. |
| [`engine`](https://github.com/Flutter-Dart-loong64/engine) | `flutter/engine` | Standalone engine fork for engine-only Loong64 patch management. This build document uses `flutter/engine/src` from the Flutter fork for current releases, because that checkout follows the Flutter framework `DEPS` revision. |
| [`native`](https://github.com/Flutter-Dart-loong64/native) | `dart-lang/native` | Native assets and FFI tooling fork. It keeps Loong64 target metadata and native asset bundling support aligned with the Dart and Flutter toolchains. |

The effective build order is:

```text
native target metadata -> Dart SDK / VM -> Flutter Engine -> Flutter SDK cache -> release archives
```

Before a dedicated Dart pub server is available, mirror Loong64-specific native-assets packages into `Flutter-Dart-loong64/pub-packages` and consume them with Git dependency overrides. Keep `Flutter-Dart-loong64/native` as the source fork for package changes, and refresh the temporary package repository when those package revisions change.

## 1. Install Packages

Install the normal Flutter Linux desktop dependencies plus LoongArch64 build tools:

```bash
sudo apt update
sudo apt install -y \
  git curl ca-certificates xz-utils unzip zip \
  python3 python3-pip \
  clang cmake ninja-build pkg-config \
  libgtk-3-dev liblzma-dev libstdc++-dev libfontconfig1-dev \
  libgl1-mesa-dev libegl1-mesa-dev \
  libx11-dev libxcursor-dev libxinerama-dev libxi-dev libxrandr-dev libxxf86vm-dev
```

Package names can vary between UOS and deepin releases. Install the equivalent GTK 3, fontconfig, OpenGL/EGL, X11, Clang, CMake, and Ninja development packages if your distribution uses different names.

## 2. Clone Sources

Choose a workspace directory first. The examples below use `WORKSPACE` instead of a machine-specific path:

```bash
export WORKSPACE=/path/to/loong64-flutter-workspace
mkdir -p "$WORKSPACE"
cd "$WORKSPACE"

git clone https://github.com/Flutter-Dart-loong64/sdk.git dart-sdk
git clone https://github.com/Flutter-Dart-loong64/flutter.git flutter
```

The current Flutter fork carries the engine source in the Flutter monorepo under `flutter/engine/src`. After syncing engine dependencies, point that engine checkout at the patched Dart SDK:

```bash
cd "$WORKSPACE/flutter/engine/src/flutter"
rm -rf third_party/dart
ln -s "$WORKSPACE/dart-sdk" third_party/dart
```

If your checkout uses `depot_tools`, add it to `PATH` before running GN or Ninja:

```bash
cd "$WORKSPACE"
git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git tools/depot_tools
export PATH="$WORKSPACE/tools/depot_tools:$PATH"
export VPYTHON_BYPASS="manually managed python not supported by chrome operations"
```

## 3. Build the Dart SDK

Build the native Loong64 release SDK:

```bash
cd "$WORKSPACE/dart-sdk"
./tools/build.py \
  -m release \
  -a loong64 \
  --gn-args="use_sysroot=false" \
  create_sdk
```

The Dart SDK should be produced under:

```text
$WORKSPACE/dart-sdk/out/ReleaseLOONG64/dart-sdk
```

Install that SDK into the Flutter checkout:

```bash
rm -rf "$WORKSPACE/flutter/bin/cache/dart-sdk"
cp -a "$WORKSPACE/dart-sdk/out/ReleaseLOONG64/dart-sdk" \
  "$WORKSPACE/flutter/bin/cache/dart-sdk"
```

Verify the Dart revision:

```bash
"$WORKSPACE/flutter/bin/cache/dart-sdk/bin/dart" --version
```

## 4. Build the Linux GTK Engine

Build the Linux release engine for Loong64. Keep `--enable-fontconfig`; it is required for normal system font fallback on UOS/deepin desktops.

```bash
cd "$WORKSPACE/flutter/engine/src"
dart_commit="$(git -C "$WORKSPACE/dart-sdk" rev-parse HEAD)"

./flutter/tools/gn \
  --linux \
  --linux-cpu loong64 \
  --runtime-mode release \
  --enable-fontconfig \
  --no-enable-unittests \
  --no-goma \
  --target-sysroot / \
  --prebuilt-dart-sdk \
  --target-dir linux_release_loong64_gtk \
  --gn-args="content_hash=\"$dart_commit\" system_libdir=\"lib/loongarch64-linux-gnu\" skia_use_vulkan=false shell_enable_vulkan=false impeller_enable_vulkan=false test_enable_vulkan=false"

ninja -C out/linux_release_loong64_gtk libflutter_linux_gtk.so gen_snapshot
```

Check that both engine binaries report the same Dart revision:

```bash
strings out/linux_release_loong64_gtk/libflutter_linux_gtk.so | grep '3.13.0-edge' | head
out/linux_release_loong64_gtk/gen_snapshot --version
```

Check that the engine links to fontconfig:

```bash
ldd out/linux_release_loong64_gtk/libflutter_linux_gtk.so | grep fontconfig
```

## 5. Install Engine Artifacts Into Flutter

The Flutter tool expects Linux release artifacts under `bin/cache/artifacts/engine/linux-loong64-release`.

```bash
engine_out="$WORKSPACE/flutter/engine/src/out/linux_release_loong64_gtk"
engine_cache="$WORKSPACE/flutter/bin/cache/artifacts/engine/linux-loong64-release"

mkdir -p "$engine_cache"
cp -a "$engine_out/libflutter_linux_gtk.so" "$engine_cache/"
cp -a "$engine_out/gen_snapshot" "$engine_cache/"
cp -a "$engine_out/icudtl.dat" "$engine_cache/" 2>/dev/null || true
cp -a "$engine_out/impellerc" "$engine_cache/" 2>/dev/null || true
cp -a "$engine_out/font-subset" "$engine_cache/" 2>/dev/null || true
cp -a "$engine_out/shader_lib" "$engine_cache/" 2>/dev/null || true
```

The Linux embedder headers live in the engine source tree. Copy them if your cache does not already contain `flutter_linux/`:

```bash
if [ ! -d "$engine_cache/flutter_linux" ]; then
  cp -a "$WORKSPACE/flutter/engine/src/flutter/shell/platform/linux/public/flutter_linux" \
    "$engine_cache/flutter_linux"
fi
```

Do not leave local backup files inside the cache before publishing a release. In particular, remove stale files such as `gen_snapshot.15f-backup` and `backup-before-*` directories from the release staging copy.

## 6. Verify Flutter

```bash
export FLUTTER_ROOT="$WORKSPACE/flutter"
export PATH="$FLUTTER_ROOT/bin:$PATH"

flutter --version --suppress-analytics
dart --version
flutter config --enable-linux-desktop
flutter config --enable-loong64
```

Build a Linux desktop app:

```bash
cd your_flutter_app
flutter pub get
flutter build linux --release --target-platform linux-loong64
```

The output bundle should be under:

```text
build/linux/loong64/release/bundle/
```

## 7. Package Release Archives

This repository includes `scripts/package-loong64-release.sh` for producing the release archives. Run it from a machine where the source tree has already been built and the Flutter cache contains matching Loong64 release engine artifacts.

```bash
git clone https://github.com/Flutter-Dart-loong64/flutter-loong64-releases.git \
  "$WORKSPACE/flutter-loong64-releases"
cd "$WORKSPACE/flutter-loong64-releases"

FLUTTER_ROOT="$WORKSPACE/flutter" \
DART_ROOT="$WORKSPACE/dart-sdk" \
ENGINE_SRC="$WORKSPACE/flutter/engine/src" \
ENGINE_OUT="$WORKSPACE/flutter/bin/cache/artifacts/engine/linux-loong64-release" \
./scripts/package-loong64-release.sh 3.46.0-1.0.pre-327 "$WORKSPACE/releases/3.46.0-1.0.pre-327"
```

Verify the archives:

```bash
cd "$WORKSPACE/releases/3.46.0-1.0.pre-327"
sha256sum -c SHA256SUMS
tar -tJf flutter-sdk-linux-loong64-*.tar.xz | grep 'linux-loong64-release/libflutter_linux_gtk.so'
```

After publishing, add a deployment record to [releases/HISTORY.md](releases/HISTORY.md) with the release tag, source commits, build target, and asset names.

## 8. Automation

`Sync Loong64 Maintenance Lines` merges upstream changes into the Loong64 maintenance branches. It uses `SYNC_TOKEN`; if the token is absent or a merge conflicts, the workflow skips without changing the fork branch.

`Flutter QEMU Loong64 Release` builds scheduled releases from upstream Dart SDK tags. It does not build from ordinary maintenance-branch merges. The scheduled run polls the latest upstream Dart tag and skips if the matching GitHub Release already has complete Loong64 assets. If a release exists but is missing assets, the workflow uploads only the missing files and keeps existing assets unchanged.

Manual Debian builds can set `dart_ref` to a `Flutter-Dart-loong64/sdk` ref, for example `main`, to build the current fork state directly. Without `dart_ref`, the workflow discovers the Loong64 commits on the fork branch ahead of upstream `main` and applies them to the selected upstream Dart SDK tag. A patch conflict, missing Loong64 commits, or missing release archives fails the workflow instead of reporting a successful publish. The default image can be overridden with the repository variable `LOONG64_QEMU_IMAGE`. Full Flutter and engine builds under QEMU can be slow; native LoongArch64 release builds remain the preferred path for production artifacts.

## 9. Common Failure Modes

- `gen_snapshot` reports `ApiError`: the Dart frontend and `gen_snapshot` are from different Dart commits. Rebuild or replace the engine artifacts so `gen_snapshot`, `libflutter_linux_gtk.so`, and the Flutter cache Dart SDK use the same Dart revision.
- Chinese text renders as boxes: rebuild the engine with `--enable-fontconfig` and verify `ldd libflutter_linux_gtk.so | grep fontconfig`.
- Flutter tries to download official Loong64 artifacts and receives 404: the local Flutter cache is incomplete or its stamp files point at artifacts that do not exist upstream. Populate `bin/cache/dart-sdk` and `bin/cache/artifacts/engine/linux-loong64-release` from the local build or published release archive.
- A release archive contains stale debug backups: remove `backup-before-*` directories and `gen_snapshot.15f-backup` before packaging.
