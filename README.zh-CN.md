# Flutter Loong64 发布包

本仓库发布面向 LoongArch64/Loong64 Linux 桌面开发的实验性 Flutter SDK、Dart SDK 和 Flutter Engine 构建产物。

源码仓库：

- Flutter SDK：<https://github.com/Flutter-Dart-loong64/flutter>
- Dart SDK：<https://github.com/Flutter-Dart-loong64/sdk>
- Flutter Engine：<https://github.com/Flutter-Dart-loong64/engine>

本仓库只发布 SDK、runtime 和 engine artifacts，不发布具体 Flutter 应用。

## 目标平台

- 架构：`loongarch64` / `loong64`
- 系统基线：UOS 25 / deepin 25 LoongArch64
- ABI：LoongArch LP64D
- 动态链接器：`/lib64/ld-linux-loongarch-lp64d.so.1`
- 桌面目标：Linux GTK

## 安装 Flutter SDK

在 LoongArch64/Loong64 UOS 或 deepin 机器上下载发布包：

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

wget https://github.com/Flutter-Dart-loong64/flutter-loong64-releases/releases/download/v2026.05.20.1/dart-sdk-linux-loong64-20260520.1-ae9f14de3805.tar.xz
tar -xf dart-sdk-linux-loong64-20260520.1-ae9f14de3805.tar.xz -C "$DART_INSTALL_DIR"

export PATH="$DART_INSTALL_DIR/dart-sdk/bin:$PATH"

dart --version
dart pub --help
```

校验 Dart SDK：

```bash
wget https://github.com/Flutter-Dart-loong64/flutter-loong64-releases/releases/download/v2026.05.20.1/SHA256SUMS
sha256sum -c SHA256SUMS --ignore-missing
```

## 从源码构建

完整源码构建流程见 [BUILDING.md](BUILDING.md)。下面是关键步骤。

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
mkdir -p "$WORKSPACE/engine/src"
cd "$WORKSPACE"

git clone https://github.com/Flutter-Dart-loong64/sdk.git dart-sdk
git clone https://github.com/Flutter-Dart-loong64/flutter.git flutter
git clone https://github.com/Flutter-Dart-loong64/engine.git engine/src/flutter
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

安装 engine artifacts 到 Flutter SDK cache：

```bash
engine_out="$WORKSPACE/engine/src/out/linux_release_loong64_gtk"
engine_cache="$WORKSPACE/flutter/bin/cache/artifacts/engine/linux-loong64-release"

mkdir -p "$engine_cache"
cp -a "$engine_out/libflutter_linux_gtk.so" "$engine_cache/"
cp -a "$engine_out/gen_snapshot" "$engine_cache/"
cp -a "$engine_out/icudtl.dat" "$engine_cache/" 2>/dev/null || true
cp -a "$engine_out/impellerc" "$engine_cache/" 2>/dev/null || true
cp -a "$engine_out/font-subset" "$engine_cache/" 2>/dev/null || true
cp -a "$engine_out/shader_lib" "$engine_cache/" 2>/dev/null || true

if [ ! -d "$engine_cache/flutter_linux" ]; then
  cp -a "$WORKSPACE/engine/src/flutter/shell/platform/linux/public/flutter_linux" \
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

## 常见问题

- `gen_snapshot` 报 `ApiError`：通常是 Dart frontend 和 `gen_snapshot` 不同版本。重新构建或替换 engine artifacts，保证 Dart SDK、`gen_snapshot`、`libflutter_linux_gtk.so` 使用同一 Dart revision。
- 中文显示为方框：确认 engine 构建时加了 `--enable-fontconfig`，并执行 `ldd libflutter_linux_gtk.so | grep fontconfig`。
- Flutter 尝试下载官方 Loong64 artifact 并返回 404：本地 Flutter cache 不完整。需要填充 `bin/cache/dart-sdk` 和 `bin/cache/artifacts/engine/linux-loong64-release`。
- 发布包里混进调试备份：打包前移除 `backup-before-*` 和 `gen_snapshot.15f-backup`。

## 状态

这是实验性 Loong64 port。当前重点是原生 Linux 桌面开发、Dart VM Loong64 backend、AOT/JIT、runtime entry，以及与 LoongArch64 系统匹配的 Flutter Engine artifacts。
