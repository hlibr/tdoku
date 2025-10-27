#!/usr/bin/env bash
set -euo pipefail

# This script builds tdoku native libraries for:
# - Android arm64-v8a (libtdoku.so)
# - Android armeabi-v7a (libtdoku.so)
# - iOS arm64 (libtdoku_static.a)
# - macOS Editor arm64 (libtdoku.dylib)
# - Windows Editor x86_64 (tdoku.dll) [run on Windows]
#
# It does NOT copy files into your Unity project automatically. After each build,
# it prints where to place the resulting binary in Unity.
#
# Prereqs:
# - SIMDe vendored under third_party/simde and built with -DUSE_SIMDE=ON for ARM targets
# - CMake >= 3.15
# - Xcode toolchain for macOS/iOS builds
# - Android NDK installed: set ANDROID_NDK_HOME or UNITY_NDK to the NDK root
# - Visual Studio (MSVC) on Windows for Windows builds

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$ROOT_DIR/build"

# Detect NDK
ANDROID_NDK_HOME="${ANDROID_NDK_HOME:-}"
UNITY_NDK="${UNITY_NDK:-}"
if [[ -z "$ANDROID_NDK_HOME" && -n "$UNITY_NDK" ]]; then
  ANDROID_NDK_HOME="$UNITY_NDK"
fi

function build_android_arm64() {
  if [[ -z "$ANDROID_NDK_HOME" ]]; then
    echo "ERROR: ANDROID_NDK_HOME or UNITY_NDK must be set to your Android NDK root" >&2
    return 1
  fi
  local bdir="$BUILD_DIR/android-arm64"
  cmake -B "$bdir" \
    -DCMAKE_BUILD_TYPE=Release \
    -DUSE_SIMDE=ON \
    -DCMAKE_TOOLCHAIN_FILE="$ANDROID_NDK_HOME/build/cmake/android.toolchain.cmake" \
    -DANDROID_ABI=arm64-v8a \
    -DANDROID_PLATFORM=21
  cmake --build "$bdir" --target tdoku_shared --config Release
  echo "Built Android arm64: $bdir/libtdoku.so"
  echo "Copy to Unity: Assets/Plugins/Android/arm64-v8a/libtdoku.so"
}

function build_android_v7() {
  if [[ -z "$ANDROID_NDK_HOME" ]]; then
    echo "ERROR: ANDROID_NDK_HOME or UNITY_NDK must be set to your Android NDK root" >&2
    return 1
  fi
  local bdir="$BUILD_DIR/android-armeabi-v7a"
  cmake -B "$bdir" \
    -DCMAKE_BUILD_TYPE=Release \
    -DUSE_SIMDE=ON \
    -DCMAKE_TOOLCHAIN_FILE="$ANDROID_NDK_HOME/build/cmake/android.toolchain.cmake" \
    -DANDROID_ABI=armeabi-v7a \
    -DANDROID_PLATFORM=16
  cmake --build "$bdir" --target tdoku_shared --config Release
  echo "Built Android v7: $bdir/libtdoku.so"
  echo "Copy to Unity: Assets/Plugins/Android/armeabi-v7a/libtdoku.so"
}

function build_ios() {
  local bdir="$BUILD_DIR/ios-arm64"
  cmake -B "$bdir" \
    -DCMAKE_BUILD_TYPE=Release \
    -DUSE_SIMDE=ON \
    -DCMAKE_OSX_ARCHITECTURES=arm64 \
    -DCMAKE_OSX_SYSROOT=iphoneos
  cmake --build "$bdir" --target tdoku_static --config Release
  echo "Built iOS static lib: $bdir/libtdoku_static.a"
  echo "Copy to Unity: Assets/Plugins/iOS/libtdoku.a (rename libtdoku_static.a -> libtdoku.a)"
}

function build_macos_editor() {
  local bdir="$BUILD_DIR/macos-arm64"
  cmake -B "$bdir" \
    -DCMAKE_BUILD_TYPE=Release \
    -DUSE_SIMDE=ON \
    -DCMAKE_OSX_ARCHITECTURES=arm64
  cmake --build "$bdir" --target tdoku_shared --config Release
  echo "Built macOS Editor dylib: $bdir/libtdoku.dylib"
  echo "Copy to Unity: Assets/Plugins/libtdoku.dylib (for Editor) and Assets/Plugins/macOS/libtdoku.dylib (for Player)"
}

function build_windows_cross_from_mac() {
  # Cross-compile Windows x86_64 DLL from macOS using mingw-w64
  # Prereqs: brew install mingw-w64
  if ! command -v x86_64-w64-mingw32-gcc >/dev/null 2>&1; then
    echo "ERROR: x86_64-w64-mingw32-gcc not found. Install mingw-w64 (brew install mingw-w64)." >&2
    return 1
  fi
  if ! command -v x86_64-w64-mingw32-g++ >/dev/null 2>&1; then
    echo "ERROR: x86_64-w64-mingw32-g++ not found. Install mingw-w64 (brew install mingw-w64)." >&2
    return 1
  fi
  if ! command -v x86_64-w64-mingw32-windres >/dev/null 2>&1; then
    echo "ERROR: x86_64-w64-mingw32-windres not found. Install mingw-w64 (brew install mingw-w64)." >&2
    return 1
  fi
  local bdir="$BUILD_DIR/win64-cross"
  CC=x86_64-w64-mingw32-gcc \
  CXX=x86_64-w64-mingw32-g++ \
  RC=x86_64-w64-mingw32-windres \
  cmake -B "$bdir" -G "MinGW Makefiles" \
    -DCMAKE_SYSTEM_NAME=Windows \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_WINDOWS_EXPORT_ALL_SYMBOLS=ON \
    -DCMAKE_SHARED_LINKER_FLAGS="-static-libstdc++ -static-libgcc"
  cmake --build "$bdir" --target tdoku_shared --config Release
  # Result should be tdoku.dll; if libtdoku.dll was produced, rename for Unity DllImport("tdoku")
  if [[ -f "$bdir/tdoku.dll" ]]; then
    echo "Built Windows x64 DLL: $bdir/tdoku.dll"
  elif [[ -f "$bdir/libtdoku.dll" ]]; then
    echo "Built Windows x64 DLL (with lib prefix): $bdir/libtdoku.dll"
    echo "You can rename to tdoku.dll for Unity if needed."
  else
    echo "WARNING: Could not find tdoku.dll in $bdir; check build logs." >&2
  fi
  echo "Copy to Unity (on Windows project): Assets/Plugins/x86_64/tdoku.dll (Editor + Windows, CPU x86_64)"
}

function build_windows_editor() {
  echo "NOTE: Run this on Windows with MSVC (Visual Studio)." >&2
  echo "Commands:" >&2
  echo "  cmake -B build-win -G \"Visual Studio 17 2022\" -A x64 -DCMAKE_BUILD_TYPE=Release" >&2
  echo "  cmake --build build-win --config Release --target tdoku_shared" >&2
  echo "Output: build-win/Release/tdoku.dll" >&2
  echo "Copy to Unity: Assets/Plugins/x86_64/tdoku.dll (and mark Editor + Windows, CPU x86_64)" >&2
}

case "${1:-all}" in
  android64)
    build_android_arm64 ;;
  androidv7)
    build_android_v7 ;;
  ios)
    build_ios ;;
  macos)
    build_macos_editor ;;
  windows)
    build_windows_editor ;;
  windows-cross)
    build_windows_cross_from_mac ;;
  all)
    build_android_arm64 || true
    build_android_v7 || true
    build_ios || true
    build_macos_editor || true
    build_windows_cross_from_mac || true
    ;;
  *)
    echo "Usage: $0 [android64|androidv7|ios|macos|windows|all]" >&2
    exit 1 ;;
 esac
