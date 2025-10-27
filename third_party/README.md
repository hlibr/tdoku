third_party dependencies

This project can optionally use SIMDe (https://github.com/simd-everywhere/simde) to provide ARM/NEON-compatible
implementations of x86 SIMD intrinsics. This is necessary to build on iOS/Android arm64.

To add SIMDe:
- Vendor SIMDe under third_party/simde (e.g., as a git submodule)
  - git submodule add https://github.com/simd-everywhere/simde.git third_party/simde
  - git submodule update --init --recursive
- Configure the build with -DUSE_SIMDE=ON so the headers are included.

The code includes include/simd_compat.h; on non-x86 platforms with USE_SIMDE, this pulls in the necessary SIMDe headers.
