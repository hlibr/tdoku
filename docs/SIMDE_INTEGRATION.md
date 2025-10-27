SIMDe integration for ARM (iOS/Android)

Overview
- The simd_vectors.h implementation uses x86 intrinsics. To build on arm64, we integrate SIMDe to map x86 intrinsics to NEON/scalar.

What changed
- New header include/simd_compat.h which uses <immintrin.h> on x86, and SIMDe headers on non-x86.
- src/simd_vectors.h now includes "simd_compat.h" instead of <immintrin.h>.
- CMakeLists.txt:
  - Added option USE_SIMDE to enable SIMDe include path and definitions.
  - Avoids x86 -m* flags on arm64 to keep builds portable.

Add SIMDe to the tree
- git submodule add https://github.com/simd-everywhere/simde.git third_party/simde
- git submodule update --init --recursive

Build examples

macOS arm64 (Apple Silicon):
  cmake -B build-macos -DCMAKE_BUILD_TYPE=Release -DUSE_SIMDE=ON
  cmake --build build-macos --target tdoku_shared

iOS arm64 (static library):
  cmake -B build-ios -DCMAKE_BUILD_TYPE=Release -DUSE_SIMDE=ON \
        -DCMAKE_OSX_ARCHITECTURES=arm64 -DCMAKE_OSX_SYSROOT=iphoneos
  cmake --build build-ios --target tdoku_static

Android arm64-v8a (NDK):
  cmake -B build-android -DCMAKE_BUILD_TYPE=Release -DUSE_SIMDE=ON \
        -DCMAKE_TOOLCHAIN_FILE=$NDK/build/cmake/android.toolchain.cmake \
        -DANDROID_ABI=arm64-v8a -DANDROID_PLATFORM=21
  cmake --build build-android --target tdoku_shared

Notes
- AVX-512 code paths in simd_vectors.h are behind feature macros and will not be compiled on ARM. SSE/SSSE3/SSE4 paths are covered by SIMDe.
- Performance should be solid on NEON; it may not match AVX2/AVX-512 on x86 but remains very fast.
