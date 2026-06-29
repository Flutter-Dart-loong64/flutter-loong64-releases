# Flutter Loong64 Releases

This repository publishes experimental LoongArch64/Loong64 builds of the Flutter SDK, Dart SDK, and Flutter Engine for native Linux desktop development.

Chinese documentation is available in [README.zh-CN.md](README.zh-CN.md).

The Loong64 port is split across four source forks:

| Repository | Upstream | Role |
| --- | --- | --- |
| [`flutter`](https://github.com/Flutter-Dart-loong64/flutter) | `flutter/flutter` | Flutter framework and tool fork. It carries Linux `loong64` target selection, host detection, cache/artifact naming, native asset integration, and the SDK packaging root. Current release builds take the engine checkout from `engine/src` inside this fork so the engine source matches Flutter `DEPS`. |
| [`sdk`](https://github.com/Flutter-Dart-loong64/sdk) | `dart-lang/sdk` | Dart SDK and VM fork. It provides the native Loong64 Dart VM backend, assembler/disassembler, JIT/AOT code generation, runtime entries, snapshot tools, and the `dart`/`gen_snapshot` binaries used by Flutter and the engine. |
| [`engine`](https://github.com/Flutter-Dart-loong64/engine) | `flutter/engine` | Standalone Flutter Engine fork for engine-only Loong64 patches and review. It is kept in sync with upstream engine, but current Flutter SDK release builds prefer the `flutter` fork's `engine/src` checkout to keep framework, engine, and `DEPS` revisions aligned. |
| [`native`](https://github.com/Flutter-Dart-loong64/native) | `dart-lang/native` | Dart native assets and FFI tooling fork. It tracks Loong64 target naming and native asset bundling support used by the Dart and Flutter toolchains. It is not published as a runtime archive here, but it is synced with the other forks so native assets stay aligned. |

Build dependency flow:

```text
native target metadata -> sdk native assets / VM support -> engine Loong64 artifacts -> flutter SDK cache -> release archives
```

Only SDK, runtime, and engine artifacts are published here. Flutter applications are outside the scope of this release repository.

Until a dedicated Dart pub server is available, Loong64-only native-assets packages can be staged in [`Flutter-Dart-loong64/pub-packages`](https://github.com/Flutter-Dart-loong64/pub-packages). That repository mirrors package sources from the `Flutter-Dart-loong64/native` fork and can be used through Git dependency overrides for packages such as `hooks_runner`, `hooks`, `code_assets`, and `data_assets`.

## Target Platform

- Architecture: `loongarch64` / `loong64`
- OS baseline: UOS 25 / deepin 25 LoongArch64
- ABI: LoongArch LP64D
- Runtime linker: `/lib64/ld-linux-loongarch-lp64d.so.1`
- Desktop target: Linux GTK

## SDK Versions

Current published release:

- Release tag: `v3.46.0-1.0.pre-327`
- Flutter SDK version: `3.46.0-1.0.pre-327`
- Flutter framework revision: `69c87127a40b5c0d735611f9026c3b16a2c02369`
- Dart SDK version: `3.13.0-edge.2ea45c8966a8f1769ce4313a80cd829f46144583`
- Dart SDK revision: `2ea45c8966a8f1769ce4313a80cd829f46144583`
- DevTools version: `2.58.0`
- Flutter Engine source revision: `69c87127a40b5c0d735611f9026c3b16a2c02369`
- Engine artifact target: `linux_loong64`
- Engine options: Linux GTK debug/profile/release builds with `--enable-fontconfig`

The release tag is the archive release version. The Flutter SDK version is the framework version reported by `flutter --version`.

## Install Flutter SDK

On a LoongArch64/Loong64 UOS or deepin machine, install the Flutter SDK archive from the release page:

```bash
export INSTALL_DIR=/path/to/install-prefix
export DOWNLOAD_DIR=/path/to/download-directory

mkdir -p "$INSTALL_DIR" "$DOWNLOAD_DIR"
cd "$DOWNLOAD_DIR"

wget https://github.com/Flutter-Dart-loong64/flutter-loong64-releases/releases/download/v3.46.0-1.0.pre-327/flutter-sdk-linux-loong64-3.46.0-1.0.pre-327-69c87127a40b.tar.xz
wget https://github.com/Flutter-Dart-loong64/flutter-loong64-releases/releases/download/v3.46.0-1.0.pre-327/SHA256SUMS

sha256sum -c SHA256SUMS

tar -xf flutter-sdk-linux-loong64-3.46.0-1.0.pre-327-69c87127a40b.tar.xz -C "$INSTALL_DIR"
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

wget https://github.com/Flutter-Dart-loong64/flutter-loong64-releases/releases/download/v3.46.0-1.0.pre-327/dart-sdk-linux-loong64-3.46.0-1.0.pre-327-2ea45c8966a8.tar.xz
tar -xf dart-sdk-linux-loong64-3.46.0-1.0.pre-327-2ea45c8966a8.tar.xz -C "$DART_INSTALL_DIR"

export PATH="$DART_INSTALL_DIR/dart-sdk/bin:$PATH"

dart --version
dart pub --help
```

To verify the Dart SDK archive with the release checksums:

```bash
wget https://github.com/Flutter-Dart-loong64/flutter-loong64-releases/releases/download/v3.46.0-1.0.pre-327/SHA256SUMS
sha256sum -c SHA256SUMS --ignore-missing
```

The published release page is:

```text
https://github.com/Flutter-Dart-loong64/flutter-loong64-releases/releases/tag/v3.46.0-1.0.pre-327
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

For the complete native source build flow, including Dart SDK, Flutter Engine, Flutter SDK cache layout, fontconfig, and release packaging, see [BUILDING.md](BUILDING.md). Published deployment records are kept in [releases/HISTORY.md](releases/HISTORY.md).

Short version for a native LoongArch64 UOS/deepin host:

```bash
export WORKSPACE=/path/to/loong64-flutter-workspace
mkdir -p "$WORKSPACE"
cd "$WORKSPACE"

git clone https://github.com/Flutter-Dart-loong64/sdk.git dart-sdk
git clone https://github.com/Flutter-Dart-loong64/flutter.git flutter
```

Build the Dart SDK:

```bash
cd dart-sdk
./tools/build.py -m release -a loong64 --gn-args="use_sysroot=false" create_sdk
```

Build the Linux GTK engine. Keep `--enable-fontconfig`; the published SDK uses fontconfig for system font fallback on LoongArch64 desktops.

```bash
cd "$WORKSPACE/flutter/engine/src"
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

- `v3.46.0-1.0.pre-327`

Release assets use this naming scheme:

- `dart-sdk-linux-loong64-<flutter-version>-<dart-commit>.tar.xz`
- `flutter-engine-linux-loong64-gtk-<flutter-version>-<engine-commit>.tar.xz`
- `flutter-sdk-linux-loong64-<flutter-version>-<flutter-commit>.tar.xz`
- `SHA256SUMS`

Each release should record source commits for Flutter SDK, Dart SDK, and Flutter Engine.

## Automation

This repository includes two GitHub Actions workflows:

- `Sync Loong64 Maintenance Lines` merges upstream changes into the `sdk`, `engine`, `flutter`, and `native` maintenance branches. It does not rewrite branch history and never builds or publishes release archives. If a merge conflicts, the workflow aborts that repository and leaves the fork unchanged.
- `Flutter QEMU Loong64 Release` builds scheduled releases from upstream Dart SDK tags. It does not build from ordinary maintenance-branch merges. The scheduled run polls the latest upstream Dart tag and skips if the matching GitHub Release already has complete Loong64 assets. If a release exists but is missing assets, the workflow uploads only missing files and keeps existing assets unchanged. For manual Debian builds that should match the current fork state, set `dart_ref` to a `Flutter-Dart-loong64/sdk` ref such as `main`; in that mode the workflow builds that fork ref directly instead of cherry-picking patches onto an upstream Dart tag. If the tag patch flow cannot apply cleanly, or if no archives are produced, the workflow fails instead of reporting a successful publish. Set the repository variable `LOONG64_QEMU_IMAGE` if the default container image is not suitable. Publishing uses version-only Git tags; asset filenames keep the `loong64` architecture marker.

The sync workflow needs a `SYNC_TOKEN` secret with write access to the fork repositories. Without that secret it exits without changing any repository.

## Status

This is an experimental Loong64 port. The current work focuses on native Linux desktop development, Dart VM backend bring-up, AOT/JIT support, and matching Flutter Engine artifacts for LoongArch64 systems.
