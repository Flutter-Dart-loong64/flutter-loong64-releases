#!/usr/bin/env bash
set -euo pipefail

: "${DART_TAG:?Set DART_TAG to an upstream dart-lang/sdk tag.}"
: "${RELEASE_ID:?Set RELEASE_ID to the release archive version.}"

export DEBIAN_FRONTEND=noninteractive
workspace="${WORKSPACE:-/work/loong64-build}"
release_repo="$(pwd)"
output_dir="$release_repo/dist/$RELEASE_ID"
dart_workspace="$workspace/dart-work"
flutter_root="$workspace/flutter"

apt-get update
apt-get install -y --no-install-recommends \
  ca-certificates curl git python3 python3-pip xz-utils unzip zip \
  build-essential clang cmake ninja-build pkg-config \
  libgtk-3-dev liblzma-dev libfontconfig1-dev \
  libgl1-mesa-dev libegl1-mesa-dev \
  libx11-dev libxcursor-dev libxinerama-dev libxi-dev libxrandr-dev libxxf86vm-dev

apt-get install -y --no-install-recommends clang-19 llvm-19 lld-19 >/dev/null 2>&1 || true

mkdir -p "$workspace" "$dart_workspace" "$output_dir"
cd "$workspace"

if [[ ! -d tools/depot_tools ]]; then
  git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git tools/depot_tools
fi

export PATH="$workspace/tools/depot_tools:$PATH"
export VPYTHON_BYPASS="manually managed python not supported by chrome operations"

if command -v clang++-19 >/dev/null 2>&1; then
  mkdir -p "$workspace/tools/clang-bin"
  for tool in clang clang++ clang-cpp llvm-ar llvm-nm llvm-objcopy llvm-readelf llvm-strip lld ld.lld; do
    if [[ -x "/usr/lib/llvm-19/bin/$tool" ]]; then
      ln -sfn "/usr/lib/llvm-19/bin/$tool" "$workspace/tools/clang-bin/$tool"
    fi
  done
  export PATH="$workspace/tools/clang-bin:$PATH"
fi

clang_major="$(clang++ --version | sed -n 's/.* version \([0-9][0-9]*\).*/\1/p' | head -1)"
if [[ -z "$clang_major" || "$clang_major" -lt 18 ]]; then
  echo "Clang 18 or newer is required by the Flutter engine libc++ checkout." >&2
  clang++ --version >&2 || true
  exit 1
fi

cd "$dart_workspace"
if [[ ! -f .gclient ]]; then
  gclient config --name=dart-sdk https://github.com/Flutter-Dart-loong64/sdk.git
fi
gclient sync -D --no-history

dart_root="$dart_workspace/dart-sdk"
cd "$dart_root"
git fetch origin main
git remote get-url upstream >/dev/null 2>&1 || git remote add upstream https://github.com/dart-lang/sdk.git
git fetch upstream main
git fetch upstream "refs/tags/$DART_TAG:refs/tags/$DART_TAG"

mapfile -t loong64_commits < <(
  git rev-list --reverse --cherry-pick --right-only upstream/main...origin/main
)

if [[ "${#loong64_commits[@]}" -eq 0 ]]; then
  echo "No Loong64 Dart SDK commits were found on the fork main branch; skipping release build."
  exit 0
fi

git checkout -B loong64-release "$DART_TAG"

for commit in "${loong64_commits[@]}"; do
  if ! git cherry-pick "$commit"; then
    git cherry-pick --abort || true
    echo "Loong64 Dart SDK patch $commit does not apply cleanly onto upstream tag $DART_TAG; skipping release build."
    exit 0
  fi
done

if [[ "$(git rev-list --count "$DART_TAG"..HEAD)" -ne "${#loong64_commits[@]}" ]]; then
  echo "Unexpected Dart SDK release commit count after applying Loong64 patches." >&2
  exit 1
fi

./tools/build.py -m release -a loong64 --no-rbe create_sdk dartaotruntime gen_snapshot analyze_snapshot

cd "$workspace"
if [[ ! -d "$flutter_root" ]]; then
  git clone https://github.com/Flutter-Dart-loong64/flutter.git "$flutter_root"
else
  git -C "$flutter_root" fetch origin master
  git -C "$flutter_root" checkout -B master origin/master
fi

cd "$flutter_root"
python3 - <<'PY'
import re
from pathlib import Path

deps = Path("DEPS").read_text()
dart_paths = sorted(set(re.findall(r"^  ['\"](engine/src/flutter/third_party/dart[^'\"]*)['\"]\s*:", deps, re.M)))
extra_paths = [
    "engine/src/flutter/third_party/dart/tools/sdks/dart-sdk:dart/dart-sdk/${platform}",
    "engine/src/flutter/third_party/gn:gn/gn/${platform}",
    "engine/src/flutter/third_party/java/openjdk:flutter/java/openjdk/${platform}",
    "third_party/ninja:infra/3pp/tools/ninja/${platform}",
]

lines = [
    "solutions = [",
    "  {",
    '    "name": ".",',
    '    "url": "https://github.com/Flutter-Dart-loong64/flutter.git",',
    '    "deps_file": "DEPS",',
    '    "managed": False,',
    '    "custom_vars": {',
    '      "download_dart_sdk": False,',
    "    },",
    '    "custom_deps": {',
]
for path in dart_paths + extra_paths:
    lines.append(f'      "{path}": None,')
lines += [
    "    },",
    "  },",
    "]",
    'target_os = ["linux"]',
    'target_cpu = ["loong64"]',
    "",
]
Path(".gclient").write_text("\n".join(lines))
PY

gclient sync -D --no-history --nohooks --ignore-dep-type=cipd -j4

engine_src="$flutter_root/engine/src"

rm -rf "$flutter_root/bin/cache/dart-sdk"
mkdir -p "$flutter_root/bin/cache"
cp -a "$dart_root/out/ReleaseLOONG64/dart-sdk" "$flutter_root/bin/cache/dart-sdk"

cd "$engine_src"
rm -rf flutter/third_party/dart flutter/prebuilts/linux-loong64
mkdir -p flutter/prebuilts/linux-loong64 flutter/third_party/gn "$flutter_root/third_party/ninja"
ln -s "$dart_root" flutter/third_party/dart
ln -s "$dart_root/out/ReleaseLOONG64/dart-sdk" flutter/prebuilts/linux-loong64/dart-sdk
ln -sfn "$(command -v gn)" flutter/third_party/gn/gn
ln -sfn "$(command -v ninja)" "$flutter_root/third_party/ninja/ninja"
dart_commit="$(git -C "$dart_root" rev-parse HEAD)"

if [[ -f flutter/third_party/vulkan-deps/glslang/src/BUILD.gn ]]; then
  perl -0pi -e 's/\n\s+"SPIRV\/spirv\.hpp11",//' flutter/third_party/vulkan-deps/glslang/src/BUILD.gn
fi

if [[ -f flutter/third_party/swiftshader/src/Reactor/BUILD.gn ]] &&
   [[ -f flutter/third_party/swiftshader/third_party/llvm-16.0/BUILD.gn ]] &&
   grep -q "swiftshader_llvm_loongarch64" flutter/third_party/swiftshader/third_party/llvm-16.0/BUILD.gn; then
  perl -0pi -e 's#llvm_dir = "\.\./\.\./third_party/llvm-10\.0"#llvm_dir = "../../third_party/llvm-16.0"#' \
    flutter/third_party/swiftshader/src/Reactor/BUILD.gn
fi

if [[ -f flutter/third_party/boringssl/src/include/openssl/target.h ]] &&
   ! grep -q "OPENSSL_LOONGARCH64" flutter/third_party/boringssl/src/include/openssl/target.h; then
  perl -0pi -e 's/#elif defined\(__riscv\) && __SIZEOF_POINTER__ == 8/#elif defined(__loongarch64)\n#define OPENSSL_64_BIT\n#define OPENSSL_LOONGARCH64\n#elif defined(__riscv) \&\& __SIZEOF_POINTER__ == 8/' \
    flutter/third_party/boringssl/src/include/openssl/target.h
fi

if [[ -f flutter/third_party/libpng/BUILD.gn ]] &&
   ! grep -q "loongarch_lsx_init.c" flutter/third_party/libpng/BUILD.gn; then
  perl -0pi -e 's/\n  if \(is_win\) \{/\n  if (current_cpu == "loong64") {\n    sources += [\n      "loongarch\/filter_lsx_intrinsics.c",\n      "loongarch\/loongarch_lsx_init.c",\n    ]\n\n    defines += [ "PNG_LOONGARCH_LSX_OPT=1" ]\n\n    cflags_c += [ "-Wno-unused-variable" ]\n  }\n\n  if (is_win) {/' \
    flutter/third_party/libpng/BUILD.gn
fi

(
  cd flutter
  "$dart_root/out/ReleaseLOONG64/dart-sdk/bin/dart" pub get --offline
)

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

ninja -C out/linux_release_loong64_gtk \
  libflutter_linux_gtk.so \
  gen_snapshot \
  font-subset \
  flutter_patched_sdk \
  sky_engine \
  const_finder

engine_cache="$flutter_root/bin/cache/artifacts/engine/linux-loong64-release"
engine_out="$engine_src/out/linux_release_loong64_gtk"
mkdir -p "$engine_cache"
cp -a "$engine_out/libflutter_linux_gtk.so" "$engine_cache/"
cp -a "$engine_out/gen_snapshot" "$engine_cache/"
cp -a "$engine_out/icudtl.dat" "$engine_cache/" 2>/dev/null || true
cp -a "$engine_out/impellerc" "$engine_cache/" 2>/dev/null || true
cp -a "$engine_out/font-subset" "$engine_cache/" 2>/dev/null || true
cp -a "$engine_out/shader_lib" "$engine_cache/" 2>/dev/null || true
mkdir -p "$flutter_root/bin/cache/artifacts/engine/linux-loong64"
cp -a "$engine_out/gen/const_finder.dart.snapshot" "$flutter_root/bin/cache/artifacts/engine/linux-loong64/" 2>/dev/null || true
cp -a "$engine_out/font-subset" "$flutter_root/bin/cache/artifacts/engine/linux-loong64/" 2>/dev/null || true
cp -a "$engine_out/gen_snapshot" "$flutter_root/bin/cache/artifacts/engine/linux-loong64/" 2>/dev/null || true
cp -a "$engine_out/icudtl.dat" "$flutter_root/bin/cache/artifacts/engine/linux-loong64/" 2>/dev/null || true
cp -a "$engine_out/impellerc" "$flutter_root/bin/cache/artifacts/engine/linux-loong64/" 2>/dev/null || true
cp -a "$engine_out/shader_lib" "$flutter_root/bin/cache/artifacts/engine/linux-loong64/" 2>/dev/null || true

if [[ -f "$engine_out/zip_archives/flutter_patched_sdk_product.zip" ]]; then
  rm -rf "$flutter_root/bin/cache/artifacts/engine/common/flutter_patched_sdk_product"
  mkdir -p "$flutter_root/bin/cache/artifacts/engine/common"
  unzip -q "$engine_out/zip_archives/flutter_patched_sdk_product.zip" \
    -d "$flutter_root/bin/cache/artifacts/engine/common"
fi

if [[ ! -d "$engine_cache/flutter_linux" ]]; then
  cp -a "$engine_src/flutter/shell/platform/linux/public/flutter_linux" "$engine_cache/flutter_linux"
fi

for mode in debug profile; do
  mode_cache="$flutter_root/bin/cache/artifacts/engine/linux-loong64-$mode"
  mkdir -p "$mode_cache"
  cp -a "$engine_cache/libflutter_linux_gtk.so" "$mode_cache/" 2>/dev/null || true
  cp -a "$engine_cache/icudtl.dat" "$mode_cache/" 2>/dev/null || true
  cp -a "$engine_cache/flutter_linux" "$mode_cache/" 2>/dev/null || true
done

engine_revision="$(git -C "$engine_src/flutter" rev-parse HEAD)"
engine_revision_date="$(git -C "$engine_src/flutter" show -s --format=%cI HEAD)"
cache_dir="$flutter_root/bin/cache"
mkdir -p "$cache_dir" "$flutter_root/bin/internal"

printf '%s\n' "$engine_revision" > "$cache_dir/engine.stamp"
printf '\n' > "$cache_dir/engine.realm"
printf '%s\n' "$engine_revision" > "$cache_dir/engine-dart-sdk.stamp"
printf '%s\n' "$engine_revision" > "$cache_dir/flutter_sdk.stamp"
printf '%s\n' "$engine_revision" > "$cache_dir/linux-sdk.stamp"
printf '%s\n' "$engine_revision" > "$cache_dir/font-subset.stamp"
printf '%s\n' "$engine_revision" > "$cache_dir/engine_stamp.stamp"
python3 - "$cache_dir/engine_stamp.json" "$engine_revision" "$engine_revision_date" <<'PY'
import json
import sys
import time
from pathlib import Path

path = Path(sys.argv[1])
engine_revision = sys.argv[2]
engine_revision_date = sys.argv[3]
stamp = {
    "build_time_ms": int(time.time() * 1000),
    "git_revision": engine_revision,
    "git_revision_date": engine_revision_date,
    "content_hash": engine_revision,
}
path.write_text(json.dumps(stamp, separators=(",", ":")) + "\n")
PY

mkdir -p "$cache_dir/pkg"
rm -rf "$cache_dir/pkg/sky_engine" "$cache_dir/pkg/flutter_gpu"
cp -a "$engine_src/flutter/sky/packages/sky_engine" "$cache_dir/pkg/sky_engine"
cp -a "$engine_src/flutter/lib/gpu" "$cache_dir/pkg/flutter_gpu"

cat > "$flutter_root/bin/internal/bootstrap.sh" <<EOF
#!/usr/bin/env bash
export FLUTTER_PREBUILT_ENGINE_VERSION="\${FLUTTER_PREBUILT_ENGINE_VERSION:-$engine_revision}"
EOF
chmod +x "$flutter_root/bin/internal/bootstrap.sh"

FLUTTER_ROOT="$flutter_root" \
DART_ROOT="$dart_root" \
ENGINE_SRC="$engine_src" \
ENGINE_OUT="$engine_cache" \
"$release_repo/scripts/package-loong64-release.sh" "$RELEASE_ID" "$output_dir"
