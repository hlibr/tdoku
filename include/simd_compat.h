#ifndef TDOKU_SIMD_COMPAT_H
#define TDOKU_SIMD_COMPAT_H

// This header provides a portable way to include SIMD intrinsics.
// - On x86/x86_64: include <immintrin.h> directly.
// - On non-x86 (e.g., arm64): use SIMDe headers to map x86 intrinsics to NEON/scalar.
//   You must vendor SIMDe into third_party/simde and set USE_SIMDE=ON in CMake.

#if defined(__x86_64__) || defined(_M_X64) || defined(__i386__) || defined(_M_IX86)
  #include <immintrin.h>
#else
  // Using SIMDe on non-x86 platforms
  // Expect SIMDe to be available in the include path (e.g., third_party/simde)
  #ifndef SIMDE_ENABLE_NATIVE_ALIASES
    #define SIMDE_ENABLE_NATIVE_ALIASES
  #endif
  // Pull in the intrinsics sets used by this project. We primarily rely on SSE2,
  // with optional SSSE3/SSE4.1/SSE4.2. AVX2/AVX-512 code paths are guarded by
  // feature macros and will not be compiled on non-x86.
  #include "simde/x86/sse2.h"
  #include "simde/x86/ssse3.h"
  #include "simde/x86/sse4.1.h"
  #include "simde/x86/sse4.2.h"
  // AVX2 header included for type completeness if needed by some toolchains.
  // Since __AVX2__ won't be defined on ARM, corresponding code paths remain inactive.
  #include "simde/x86/avx2.h"
  // AVX-512 not included; code has fallbacks when those macros are not defined.
#endif

#endif // TDOKU_SIMD_COMPAT_H
