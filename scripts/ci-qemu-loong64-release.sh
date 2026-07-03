#!/usr/bin/env bash
set -euo pipefail

: "${RELEASE_ID:?Set RELEASE_ID to the release archive version.}"
: "${BOOTSTRAP_DART_SDK_URL:?Set BOOTSTRAP_DART_SDK_URL to a Loong64 Dart SDK archive URL.}"

dart_ref="${DART_REF:-}"
flutter_ref="${FLUTTER_REF:-loong64-main}"
sdk_bootstrap_ref="${dart_ref:-main}"
if [[ -z "$dart_ref" ]]; then
  : "${DART_TAG:?Set DART_TAG to an upstream dart-lang/sdk tag, or set DART_REF to a Flutter-Dart-loong64/sdk ref.}"
fi

export DEBIAN_FRONTEND=noninteractive
workspace="${WORKSPACE:-/work/loong64-build}"
release_repo="$(pwd)"
output_dir="$release_repo/dist/$RELEASE_ID"
dart_workspace="$workspace/dart-work"
flutter_root="$workspace/flutter"

apt-get update
apt-get install -y --no-install-recommends \
  ca-certificates curl git python3 python3-pip xz-utils unzip zip \
  python3-httplib2 python3-six \
  build-essential clang cmake generate-ninja ninja-build pkg-config \
  libgtk-3-dev liblzma-dev libfontconfig1-dev \
  libgl1-mesa-dev libegl1-mesa-dev \
  libx11-dev libxcursor-dev libxinerama-dev libxi-dev libxrandr-dev libxxf86vm-dev

apt-get install -y --no-install-recommends clang-19 llvm-19 lld-19 >/dev/null 2>&1 || true

system_gn="$(command -v gn || true)"
system_ninja="$(command -v ninja || true)"
if [[ -z "$system_gn" || -z "$system_ninja" ]]; then
  echo "Debian Loong64 build tools are incomplete; gn and ninja are required." >&2
  echo "gn: ${system_gn:-missing}" >&2
  echo "ninja: ${system_ninja:-missing}" >&2
  exit 1
fi

mkdir -p "$workspace" "$dart_workspace" "$output_dir"
cd "$workspace"

git config --global user.name "${GIT_COMMITTER_NAME:-guanzi008}"
git config --global user.email "${GIT_COMMITTER_EMAIL:-245205080@qq.com}"

patch_boringssl_loong64_target() {
  local target_h="$1"

  if [[ -f "$target_h" ]] && ! grep -q "OPENSSL_LOONGARCH64" "$target_h"; then
    perl -0pi -e 's/#elif defined\(__riscv\) && __SIZEOF_POINTER__ == 8/#elif defined(__loongarch64) || (defined(__loongarch__) \&\& __loongarch_grlen == 64)\n#define OPENSSL_64_BIT\n#define OPENSSL_LOONGARCH64\n#elif defined(__riscv) \&\& __SIZEOF_POINTER__ == 8/' \
      "$target_h"
  fi
}

if [[ ! -d tools/depot_tools ]]; then
  git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git tools/depot_tools
fi

export PATH="$workspace/tools/depot_tools:$PATH"
export VPYTHON_BYPASS="manually managed python not supported by chrome operations"
gclient=(python3 "$workspace/tools/depot_tools/gclient.py")

if command -v clang++-19 >/dev/null 2>&1; then
  mkdir -p "$workspace/tools/clang-bin"
  for tool in clang clang++ clang-cpp llvm-ar llvm-ranlib llvm-nm llvm-objcopy llvm-objdump llvm-readelf llvm-strip lld ld.lld; do
    if [[ -x "/usr/lib/llvm-19/bin/$tool" ]]; then
      ln -sfn "/usr/lib/llvm-19/bin/$tool" "$workspace/tools/clang-bin/$tool"
      if [[ "$tool" == llvm-* && ! -e "/usr/bin/$tool" ]]; then
        ln -sfn "/usr/lib/llvm-19/bin/$tool" "/usr/bin/$tool"
      fi
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
cat > .gclient <<'EOF'
solutions = [
  {
    "name": "sdk",
    "url": "https://github.com/Flutter-Dart-loong64/sdk.git",
    "deps_file": "DEPS",
    "managed": False,
  },
]
target_os = ["linux"]
target_cpu = ["loong64"]
EOF

if [[ ! -d sdk/.git ]]; then
  git clone --no-checkout https://github.com/Flutter-Dart-loong64/sdk.git sdk
fi
if [[ -d sdk/.git ]]; then
  for dep in sdk/third_party/boringssl/src sdk/third_party/devtools; do
    if [[ -d "$dep/.git" ]]; then
      git -C "$dep" reset --hard
      git -C "$dep" clean -fd
    fi
  done
  git -C sdk remote set-url origin https://github.com/Flutter-Dart-loong64/sdk.git
  git -C sdk fetch --no-tags origin "$sdk_bootstrap_ref"
  git -C sdk checkout -B loong64-bootstrap FETCH_HEAD
fi
"${gclient[@]}" sync -D --no-history --nohooks --ignore-dep-type=cipd

dart_root="$dart_workspace/sdk"
cd "$dart_root"
git fetch --no-tags origin "$sdk_bootstrap_ref"
git remote get-url upstream >/dev/null 2>&1 || git remote add upstream https://github.com/dart-lang/sdk.git

if [[ -n "$dart_ref" ]]; then
  if ! git fetch --no-tags origin "$dart_ref"; then
    git fetch origin "$dart_ref"
  fi
  git checkout -B loong64-release FETCH_HEAD
else
  git fetch --no-tags upstream main
  git fetch --no-tags --depth=1 upstream "refs/tags/$DART_TAG:refs/tags/$DART_TAG"

  if [[ "$(git rev-parse --is-shallow-repository)" == "true" ]]; then
    for deepen_by in 8 64 512; do
      if git merge-base upstream/main origin/main >/dev/null 2>&1; then
        break
      fi
      git fetch --no-tags --deepen="$deepen_by" origin main
    done

    if ! git merge-base upstream/main origin/main >/dev/null 2>&1; then
      git fetch --no-tags --unshallow origin main
    fi
  fi

  if ! git merge-base upstream/main origin/main >/dev/null 2>&1; then
    echo "Unable to find a merge base between upstream/main and the Loong64 fork main branch." >&2
    exit 1
  fi

  mapfile -t loong64_commits < <(
    git rev-list --reverse --cherry-pick --right-only upstream/main...origin/main
  )

  if [[ "${#loong64_commits[@]}" -eq 0 ]]; then
    echo "No Loong64 Dart SDK commits were found on the fork main branch." >&2
    exit 1
  fi

  git checkout -B loong64-release "$DART_TAG"

  for commit in "${loong64_commits[@]}"; do
    if ! git cherry-pick "$commit"; then
      git cherry-pick --abort || true
      echo "Loong64 Dart SDK patch $commit does not apply cleanly onto upstream tag $DART_TAG." >&2
      exit 1
    fi
  done

  if [[ "$(git rev-list --count "$DART_TAG"..HEAD)" -ne "${#loong64_commits[@]}" ]]; then
    echo "Unexpected Dart SDK release commit count after applying Loong64 patches." >&2
    exit 1
  fi
fi

"${gclient[@]}" sync -D --no-history --nohooks --ignore-dep-type=cipd

ensure_devtools_checkout() {
  local devtools_rev devtools_dir

  devtools_rev="$(
    python3 - <<'PY'
from pathlib import Path
import re

deps = Path("DEPS").read_text()
match = re.search(r'"devtools_rev":\s*"([^"]+)"', deps)
if not match:
    raise SystemExit("Unable to find devtools_rev in Dart SDK DEPS")
print(match.group(1))
PY
  )"
  devtools_dir="$dart_root/third_party/devtools"

  if [[ ! -d "$devtools_dir/.git" ]]; then
    rm -rf "$devtools_dir"
    git clone --no-checkout https://github.com/flutter/devtools.git "$devtools_dir"
  fi

  if ! git -C "$devtools_dir" cat-file -e "$devtools_rev^{commit}" 2>/dev/null; then
    git -C "$devtools_dir" fetch --no-tags --depth=1 origin "$devtools_rev" ||
      git -C "$devtools_dir" fetch --no-tags --depth=256 origin main master
  fi

  git -C "$devtools_dir" checkout --detach "$devtools_rev"
  ln -sfn packages/devtools_shared "$devtools_dir/devtools_shared"
  ln -sfn packages/devtools_app/web "$devtools_dir/web"
}

rm -rf tools/sdks/dart-sdk
mkdir -p tools/sdks
curl -L --fail --retry 3 "$BOOTSTRAP_DART_SDK_URL" -o "$workspace/bootstrap-dart-sdk.tar.xz"
tar -xJf "$workspace/bootstrap-dart-sdk.tar.xz" -C tools/sdks
if [[ ! -x tools/sdks/dart-sdk/bin/dart ]]; then
  echo "The Loong64 Dart SDK bootstrap archive did not provide tools/sdks/dart-sdk/bin/dart." >&2
  exit 1
fi

ensure_devtools_checkout
patch_boringssl_loong64_target third_party/boringssl/src/include/openssl/target.h
python3 tools/generate_package_config.py
python3 tools/generate_sdk_version_file.py

mkdir -p buildtools/ninja
ln -sfn "$system_gn" buildtools/gn
ln -sfn "$system_ninja" buildtools/ninja/ninja

./tools/build.py -m release -a loong64 --no-rbe create_sdk dartaotruntime gen_snapshot analyze_snapshot

cd "$workspace"
if [[ ! -d "$flutter_root" ]]; then
  git clone --no-checkout https://github.com/Flutter-Dart-loong64/flutter.git "$flutter_root"
else
  git -C "$flutter_root" remote set-url origin https://github.com/Flutter-Dart-loong64/flutter.git
fi
git -C "$flutter_root" fetch --no-tags origin "$flutter_ref"
git -C "$flutter_root" checkout -B loong64-release-flutter FETCH_HEAD

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
    if path == "engine/src/flutter/third_party/dart":
        continue
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

"${gclient[@]}" sync -D --no-history --nohooks --ignore-dep-type=cipd -j4

engine_src="$flutter_root/engine/src"

rm -rf "$flutter_root/bin/cache/dart-sdk"
mkdir -p "$flutter_root/bin/cache"
cp -a "$dart_root/out/ReleaseLOONG64/dart-sdk" "$flutter_root/bin/cache/dart-sdk"

cd "$engine_src"
rm -rf flutter/third_party/dart flutter/prebuilts/linux-loong64
mkdir -p flutter/prebuilts/linux-loong64 flutter/third_party/gn "$flutter_root/third_party/ninja"
ln -s "$dart_root" flutter/third_party/dart
ln -s "$dart_root/out/ReleaseLOONG64/dart-sdk" flutter/prebuilts/linux-loong64/dart-sdk
ln -sfn "$system_gn" flutter/third_party/gn/gn
ln -sfn "$system_ninja" "$flutter_root/third_party/ninja/ninja"
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

patch_boringssl_loong64_target flutter/third_party/boringssl/src/include/openssl/target.h

if [[ -f flutter/third_party/libpng/BUILD.gn ]] &&
   ! grep -q "loongarch_lsx_init.c" flutter/third_party/libpng/BUILD.gn; then
  perl -0pi -e 's/\n  if \(is_win\) \{/\n  if (current_cpu == "loong64") {\n    sources += [\n      "loongarch\/filter_lsx_intrinsics.c",\n      "loongarch\/loongarch_lsx_init.c",\n    ]\n\n    defines += [ "PNG_LOONGARCH_LSX_OPT=1" ]\n\n    cflags_c += [ "-Wno-unused-variable" ]\n  }\n\n  if (is_win) {/' \
    flutter/third_party/libpng/BUILD.gn
fi

(
  cd flutter
  "$dart_root/out/ReleaseLOONG64/dart-sdk/bin/dart" pub get
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
