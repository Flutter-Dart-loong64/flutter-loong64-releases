# Flutter Loong64 发布包

本仓库发布面向 LoongArch64/Loong64 Linux 桌面开发的实验性 Flutter SDK、Dart SDK 和 Flutter Engine 构建产物。

Loong64 适配拆在四个源码 fork 中维护：

| 仓库 | 上游 | 职责 |
| --- | --- | --- |
| [`flutter`](https://github.com/Flutter-Dart-loong64/flutter) | `flutter/flutter` | Flutter framework 和 tool fork。这里维护 Linux `loong64` 目标选择、主机架构识别、cache/artifact 命名、native assets 集成，以及 Flutter SDK 发布包根目录。当前发布构建使用该 fork 内部的 `engine/src`，保证 framework、engine 和 Flutter `DEPS` revision 对齐。 |
| [`sdk`](https://github.com/Flutter-Dart-loong64/sdk) | `dart-lang/sdk` | Dart SDK 和 VM fork。这里维护 Loong64 Dart VM backend、assembler/disassembler、JIT/AOT codegen、runtime entry、snapshot 工具，以及 Flutter/engine 使用的 `dart`、`gen_snapshot` 二进制。 |
| [`engine`](https://github.com/Flutter-Dart-loong64/engine) | `flutter/engine` | 独立 Flutter Engine fork，用来维护和审查 engine-only 的 Loong64 补丁，并跟随上游 engine 同步。当前 Flutter SDK 发布构建优先使用 `flutter` fork 内的 `engine/src`，避免 framework、engine、`DEPS` revision 错位。 |
| [`native`](https://github.com/Flutter-Dart-loong64/native) | `dart-lang/native` | Dart native assets 和 FFI tooling fork。这里跟踪 Loong64 target 命名和 native asset bundling 支持，供 Dart/Flutter 工具链使用。本仓库不单独发布它的运行时包，但会和其他 fork 一起同步，避免 native assets 支持脱节。 |

构建依赖流向：

```text
native target metadata -> sdk native assets / VM support -> engine Loong64 artifacts -> flutter SDK cache -> release archives
```

本仓库只发布 SDK、runtime 和 engine artifacts，不发布具体 Flutter 应用。

## 目标平台

- 架构：`loongarch64` / `loong64`
- 系统基线：UOS 25 / deepin 25 LoongArch64
- ABI：LoongArch LP64D
- 动态链接器：`/lib64/ld-linux-loongarch-lp64d.so.1`
- 桌面目标：Linux GTK

## SDK 版本

当前发布版本：

- Release tag：`v3.45.0-1.0.pre-174`
- Flutter SDK 版本：`3.45.0-1.0.pre-174`
- Flutter framework revision：`d2285105069eeaaae77619ddf63627bf646dcbf4`
- Dart SDK 版本：`3.13.0-127.0.dev`
- DevTools 版本：`2.58.0`
- Flutter Engine 源码 revision：`d2285105069eeaaae77619ddf63627bf646dcbf4`
- Engine content hash：`6f13d76618c7235203458cb1b67b0dbb6fb15af9`
- Engine artifact 目标：`linux_loong64`
- Engine 构建选项：Linux GTK release，启用 `--enable-fontconfig`

Release tag 是发布包版本号；Flutter SDK 版本以 `flutter --version` 输出的 framework 版本为准。

## 安装 Flutter SDK

在 LoongArch64/Loong64 UOS 或 deepin 机器上下载发布包：

```bash
export INSTALL_DIR=/path/to/install-prefix
export DOWNLOAD_DIR=/path/to/download-directory

mkdir -p "$INSTALL_DIR" "$DOWNLOAD_DIR"
cd "$DOWNLOAD_DIR"

wget https://github.com/Flutter-Dart-loong64/flutter-loong64-releases/releases/download/v3.45.0-1.0.pre-174/flutter-sdk-linux-loong64-3.45.0-1.0.pre-174-d2285105069e.tar.xz
wget https://github.com/Flutter-Dart-loong64/flutter-loong64-releases/releases/download/v3.45.0-1.0.pre-174/SHA256SUMS

sha256sum -c SHA256SUMS

tar -xf flutter-sdk-linux-loong64-3.45.0-1.0.pre-174-d2285105069e.tar.xz -C "$INSTALL_DIR"
```

配置环境变量：

```bash
export FLUTTER_ROOT="$INSTALL_DIR/flutter"
export PATH="$FLUTTER_ROOT/bin:$PATH"
```

如果需要长期生效，把上面两行加入你的 shell 配置文件。

验证安装：

```bash
flutter --version --suppress-analytics
dart --version
```

启用 Linux 桌面和 Loong64 支持：

```bash
flutter config --enable-linux-desktop
flutter config --enable-loong64
```

构建 Loong64 原生 Linux 桌面应用：

```bash
cd your_flutter_app
flutter pub get
flutter build linux --release --target-platform linux-loong64
```

构建产物通常位于：

```bash
build/linux/loong64/release/bundle/
```

## 仅安装 Dart SDK

如果只需要 Dart SDK：

```bash
export DART_INSTALL_DIR=/path/to/install-prefix
export DART_DOWNLOAD_DIR=/path/to/download-directory

mkdir -p "$DART_INSTALL_DIR" "$DART_DOWNLOAD_DIR"
cd "$DART_DOWNLOAD_DIR"

wget https://github.com/Flutter-Dart-loong64/flutter-loong64-releases/releases/download/v3.45.0-1.0.pre-174/dart-sdk-linux-loong64-3.45.0-1.0.pre-174-e650d226331b.tar.xz
tar -xf dart-sdk-linux-loong64-3.45.0-1.0.pre-174-e650d226331b.tar.xz -C "$DART_INSTALL_DIR"

export PATH="$DART_INSTALL_DIR/dart-sdk/bin:$PATH"

dart --version
dart pub --help
```

校验 Dart SDK：

```bash
wget https://github.com/Flutter-Dart-loong64/flutter-loong64-releases/releases/download/v3.45.0-1.0.pre-174/SHA256SUMS
sha256sum -c SHA256SUMS --ignore-missing
```

## 从源码构建

完整源码构建流程见 [BUILDING.md](BUILDING.md)。历史发布部署信息单独记录在 [releases/HISTORY.md](releases/HISTORY.md)。下面是关键步骤。

安装依赖：

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

拉取源码：

```bash
export WORKSPACE=/path/to/loong64-flutter-workspace
mkdir -p "$WORKSPACE"
cd "$WORKSPACE"

git clone https://github.com/Flutter-Dart-loong64/sdk.git dart-sdk
git clone https://github.com/Flutter-Dart-loong64/flutter.git flutter
```

构建 Dart SDK：

```bash
cd "$WORKSPACE/dart-sdk"
./tools/build.py \
  -m release \
  -a loong64 \
  --gn-args="use_sysroot=false" \
  create_sdk

rm -rf "$WORKSPACE/flutter/bin/cache/dart-sdk"
cp -a "$WORKSPACE/dart-sdk/out/ReleaseLOONG64/dart-sdk" \
  "$WORKSPACE/flutter/bin/cache/dart-sdk"
```

构建 Linux GTK Engine。必须保留 `--enable-fontconfig`，否则 UOS/deepin 上中文字体 fallback 容易异常：

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

安装 engine artifacts 到 Flutter SDK cache：

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

if [ ! -d "$engine_cache/flutter_linux" ]; then
  cp -a "$WORKSPACE/flutter/engine/src/flutter/shell/platform/linux/public/flutter_linux" \
    "$engine_cache/flutter_linux"
fi
```

验证 engine 和 Dart 版本一致：

```bash
strings "$engine_cache/libflutter_linux_gtk.so" | grep '3.13.0-edge' | head
"$engine_cache/gen_snapshot" --version
ldd "$engine_cache/libflutter_linux_gtk.so" | grep fontconfig
```

注意：`gen_snapshot`、`libflutter_linux_gtk.so`、Flutter cache 里的 Dart SDK 必须来自同一个 Dart revision。不要混用不同提交的 AOT 产物和 engine runtime。

## 发布包命名

Git tag 使用纯版本号，不把架构写进 tag，例如：

- `v2026.05.20.1`

资产文件名保留架构信息：

- `dart-sdk-linux-loong64-YYYYMMDD.N-<dart-commit>.tar.xz`
- `flutter-engine-linux-loong64-gtk-YYYYMMDD.N-<engine-commit>-dart<dart-commit>-fontconfig.tar.xz`
- `flutter-sdk-linux-loong64-YYYYMMDD.N-<flutter-commit>-dart<dart-commit>-engine<engine-commit>-fontconfig.tar.xz`
- `SHA256SUMS`

## 自动化

本仓库包含两个 GitHub Actions workflow：

- `Sync Loong64 Forks`：把 `sdk`、`engine`、`flutter`、`native` fork 分支变基到各自上游分支。它只更新 fork 分支，不构建、不发布 release。发生冲突时对应仓库会中止并跳过，不会改动 fork。
- `Dart Tag QEMU Loong64 Release`：只基于上游 Dart SDK tag 构建发布包，不因普通分支变基或 fork 提交触发发布构建。定时任务检测最新上游 Dart tag，如果对应 GitHub Release 已存在就跳过。它只会把 fork 分支相对上游 `main` 多出来的 Loong64 提交应用到目标 tag；如果补丁无法干净应用到该 tag，本次发布构建会跳过。默认容器镜像不适用时，可以通过仓库变量 `LOONG64_QEMU_IMAGE` 指定镜像。发布 tag 使用纯版本号，例如 `v3.13.0`；资产文件名中保留 `loong64` 架构标识。

同步 fork 需要配置 `SYNC_TOKEN` secret，并给它 fork 仓库写权限；没有这个 secret 时 workflow 会直接跳过，不改动任何仓库。

## 常见问题

- `gen_snapshot` 报 `ApiError`：通常是 Dart frontend 和 `gen_snapshot` 不同版本。重新构建或替换 engine artifacts，保证 Dart SDK、`gen_snapshot`、`libflutter_linux_gtk.so` 使用同一 Dart revision。
- 中文显示为方框：确认 engine 构建时加了 `--enable-fontconfig`，并执行 `ldd libflutter_linux_gtk.so | grep fontconfig`。
- Flutter 尝试下载官方 Loong64 artifact 并返回 404：本地 Flutter cache 不完整。需要填充 `bin/cache/dart-sdk` 和 `bin/cache/artifacts/engine/linux-loong64-release`。
- 发布包里混进调试备份：打包前移除 `backup-before-*` 和 `gen_snapshot.15f-backup`。

## 状态

这是实验性 Loong64 port。当前重点是原生 Linux 桌面开发、Dart VM Loong64 backend、AOT/JIT、runtime entry，以及与 LoongArch64 系统匹配的 Flutter Engine artifacts。
