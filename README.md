# Flutter Loong64 Releases

This repository publishes experimental LoongArch64/Loong64 builds of the Flutter SDK, Dart SDK, and Flutter Engine for native Linux desktop development.

Chinese documentation is available in [README.zh-CN.md](README.zh-CN.md).

The source branches used for these builds live in:

- Flutter SDK: <https://github.com/Flutter-Dart-loong64/flutter>
- Dart SDK: <https://github.com/Flutter-Dart-loong64/sdk>
- Flutter Engine: <https://github.com/Flutter-Dart-loong64/engine>

Only SDK, runtime, and engine artifacts are published here. Flutter applications are outside the scope of this release repository.

## Target Platform

- Architecture: `loongarch64` / `loong64`
- OS baseline: UOS 25 / deepin 25 LoongArch64
- ABI: LoongArch LP64D
- Runtime linker: `/lib64/ld-linux-loongarch-lp64d.so.1`
- Desktop target: Linux GTK

## SDK Versions

Current published release:

- Release tag: `v2026.05.20.1`
- Flutter SDK version: `3.44.0-1.0.pre-616`
- Flutter framework revision: `9b43981fc5d61f877795b4dad64d0cc67671753d`
- Dart SDK version: `3.13.0-edge.ae9f14de38050f38180626ad07d8252ee2e968f5`
- DevTools version: `2.58.0`
- Flutter Engine source revision: `a7a98649a2c80b8a9839795680853428ff6de311`
- Engine artifact target: `linux_loong64`
- Engine options: Linux GTK release build with `--enable-fontconfig`

The release tag is the archive release version. The Flutter SDK version is the framework version reported by `flutter --version`.

## Install Flutter SDK

On a LoongArch64/Loong64 UOS or deepin machine, install the Flutter SDK archive from the release page:

```bash
export INSTALL_DIR=/path/to/install-prefix
export DOWNLOAD_DIR=/path/to/download-directory

mkdir -p "$INSTALL_DIR" "$DOWNLOAD_DIR"
cd "$DOWNLOAD_DIR"

wget https://github.com/Flutter-Dart-loong64/flutter-loong64-releases/releases/download/v2026.05.20.1/flutter-sdk-linux-loong64-20260520.1-9b43981fc5d6-dartae9f14de3805-enginea7a98649a2c8-fontconfig.tar.xz
wget https://github.com/Flutter-Dart-loong64/flutter-loong64-releases/releases/download/v2026.05.20.1/SHA256SUMS

sha256sum -c SHA256SUMS

tar -xf flutter-sdk-linux-loong64-20260520.1-9b43981fc5d6-dartae9f14de3805-enginea7a98649a2c8-fontconfig.tar.xz -C "$INSTALL_DIR"
```

Add Flutter to your shell environment. Put these exports in your shell profile if you want them to persist:

```bash
export FLUTTER_ROOT="$INSTALL_DIR/flutter"
export PATH="$FLUTTER_ROOT/bin:$PATH"
```

Verify the install:

```bash
flutter --version --suppress-analytics
dart --version
```

Enable Linux desktop and Loong64 support:

```bash
flutter config --enable-linux-desktop
flutter config --enable-loong64
```

Build a native Loong64 Linux desktop application:

```bash
cd your_flutter_app
flutter pub get
flutter build linux --release --target-platform linux-loong64
```

The release bundle is normally created under:

```bash
build/linux/loong64/release/bundle/
```

The patched Flutter tool recognizes `loongarch64` hosts, uses `linux-loong64` engine artifacts, and supports `linux-loong64` as a Linux desktop target platform.

## Install Dart SDK Only

If you only need the Dart SDK:

```bash
export DART_INSTALL_DIR=/path/to/install-prefix
export DART_DOWNLOAD_DIR=/path/to/download-directory

mkdir -p "$DART_INSTALL_DIR" "$DART_DOWNLOAD_DIR"
cd "$DART_DOWNLOAD_DIR"

wget https://github.com/Flutter-Dart-loong64/flutter-loong64-releases/releases/download/v2026.05.20.1/dart-sdk-linux-loong64-20260520.1-ae9f14de3805.tar.xz
tar -xf dart-sdk-linux-loong64-20260520.1-ae9f14de3805.tar.xz -C "$DART_INSTALL_DIR"

export PATH="$DART_INSTALL_DIR/dart-sdk/bin:$PATH"

dart --version
dart pub --help
```

To verify the Dart SDK archive with the release checksums:

```bash
wget https://github.com/Flutter-Dart-loong64/flutter-loong64-releases/releases/download/v2026.05.20.1/SHA256SUMS
sha256sum -c SHA256SUMS --ignore-missing
```

The published release page is:

```text
https://github.com/Flutter-Dart-loong64/flutter-loong64-releases/releases/tag/v2026.05.20.1
```

For temporary one-shell use without changing `.bashrc`:

```bash
export PATH="$DART_INSTALL_DIR/dart-sdk/bin:$PATH"
dart --version
```

The Dart SDK contains native Loong64 `dart`, `gen_snapshot`, VM runtime, assembler/disassembler, JIT/AOT code generation, runtime entry, and ELF/AOT snapshot support from the Loong64 backend branch.

## Engine Artifacts

The engine archive contains Linux GTK Loong64 artifacts built on a native LoongArch64 machine. Typical contents include:

- `libflutter_linux_gtk.so`
- `gen_snapshot`
- `icudtl.dat`
- `flutter_linux/` embedder headers and CMake metadata

To use a local engine with Flutter:

```bash
export FLUTTER_ENGINE=/path/to/engine/src
flutter build linux \
  --release \
  --target-platform linux-loong64 \
  --local-engine-src-path "$FLUTTER_ENGINE" \
  --local-engine linux_release_loong64_gtk
```

For SDK users, the published Flutter SDK archive is expected to already include matching `bin/cache/artifacts/engine/linux-loong64*` artifacts.

## System Packages

Install the normal Linux desktop build dependencies for Flutter, plus LoongArch64 compiler and GTK development packages:

```bash
sudo apt update
sudo apt install -y \
  clang cmake ninja-build pkg-config git xz-utils unzip zip \
  libgtk-3-dev liblzma-dev libstdc++-dev
```

Package names may vary slightly across UOS/deepin releases.

## Build From Source

For the complete native source build flow, including Dart SDK, Flutter Engine, Flutter SDK cache layout, fontconfig, and release packaging, see [BUILDING.md](BUILDING.md).

Short version for a native LoongArch64 UOS/deepin host:

```bash
export WORKSPACE=/path/to/loong64-flutter-workspace
mkdir -p "$WORKSPACE/engine/src"
cd "$WORKSPACE"

git clone https://github.com/Flutter-Dart-loong64/sdk.git dart-sdk
git clone https://github.com/Flutter-Dart-loong64/flutter.git flutter
git clone https://github.com/Flutter-Dart-loong64/engine.git engine/src/flutter
```

Build the Dart SDK:

```bash
cd dart-sdk
./tools/build.py -m release -a loong64 --gn-args="use_sysroot=false" create_sdk
```

Build the Linux GTK engine. Keep `--enable-fontconfig`; the published SDK uses fontconfig for system font fallback on LoongArch64 desktops.

```bash
cd "$WORKSPACE/engine/src"
export VPYTHON_BYPASS="manually managed python not supported by chrome operations"
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

After building, copy `libflutter_linux_gtk.so` and `gen_snapshot` into `flutter/bin/cache/artifacts/engine/linux-loong64-release/`, keeping both files on the same Dart/engine revision. Do not mix `gen_snapshot`, `libapp.so`, and `libflutter_linux_gtk.so` from different Dart commits.

## Release Naming

Git tags use a version-only scheme and do not include the target architecture, for example:

- `v2026.05.20.1`

Release assets use this naming scheme:

- `dart-sdk-linux-loong64-YYYYMMDD.N-<dart-commit>.tar.xz`
- `flutter-engine-linux-loong64-gtk-YYYYMMDD.N-<engine-commit>-dart<dart-commit>-fontconfig.tar.xz`
- `flutter-sdk-linux-loong64-YYYYMMDD.N-<flutter-commit>-dart<dart-commit>-engine<engine-commit>-fontconfig.tar.xz`
- `SHA256SUMS`

Each release should record source commits for Flutter SDK, Dart SDK, and Flutter Engine.

## Status

This is an experimental Loong64 port. The current work focuses on native Linux desktop development, Dart VM backend bring-up, AOT/JIT support, and matching Flutter Engine artifacts for LoongArch64 systems.
