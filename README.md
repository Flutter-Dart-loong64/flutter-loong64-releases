# Flutter Loong64 Releases

This repository publishes experimental LoongArch64/Loong64 builds of the Flutter SDK, Dart SDK, and Flutter Engine for native Linux desktop development.

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

## Install Flutter SDK

Download the Flutter SDK archive from this repository's GitHub Releases page, then extract it:

```bash
mkdir -p "$HOME/opt"
tar -xf flutter-sdk-linux-loong64-*.tar.xz -C "$HOME/opt"
export FLUTTER_ROOT="$HOME/opt/flutter"
export PATH="$FLUTTER_ROOT/bin:$PATH"
```

Enable Linux desktop and Loong64 support:

```bash
flutter config --enable-linux-desktop
flutter config --enable-loong64
```

For a native Loong64 Linux desktop build:

```bash
flutter build linux --release --target-platform linux-loong64
```

The patched Flutter tool recognizes `loongarch64` hosts, uses `linux-loong64` engine artifacts, and supports `linux-loong64` as a Linux desktop target platform.

## Install Dart SDK Only

Download the Dart SDK archive from GitHub Releases and extract it:

```bash
mkdir -p "$HOME/opt"
tar -xf dart-sdk-linux-loong64-*.tar.xz -C "$HOME/opt"
export PATH="$HOME/opt/dart-sdk/bin:$PATH"
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
export FLUTTER_ENGINE="$HOME/src/engine/src"
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

Clone the patched repositories:

```bash
git clone https://github.com/Flutter-Dart-loong64/sdk.git dart-sdk
git clone https://github.com/Flutter-Dart-loong64/flutter.git flutter
git clone https://github.com/Flutter-Dart-loong64/engine.git engine/src/flutter
```

Build Dart SDK on a native LoongArch64 host:

```bash
cd dart-sdk
./tools/build.py -m release -a loong64 --gn-args="use_sysroot=false" create_sdk
```

Build the Linux GTK engine on a native LoongArch64 host:

```bash
cd engine/src/flutter
ninja -C ../out/linux_release_loong64_gtk flutter/shell/platform/linux:flutter_gtk
```

## Release Naming

Release assets use this naming scheme:

- `dart-sdk-linux-loong64-YYYYMMDD-<commit>.tar.xz`
- `flutter-engine-linux-loong64-gtk-YYYYMMDD-<commit>.tar.xz`
- `flutter-sdk-linux-loong64-YYYYMMDD-<commit>.tar.xz`
- `SHA256SUMS`

Each release should record source commits for Flutter SDK, Dart SDK, and Flutter Engine.

## Status

This is an experimental Loong64 port. The current work focuses on native Linux desktop development, Dart VM backend bring-up, AOT/JIT support, and matching Flutter Engine artifacts for LoongArch64 systems.
