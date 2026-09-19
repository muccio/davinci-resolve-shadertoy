# Design Document: DaVinci Resolve Shadertoy Generator Plugin (macOS / Cross-Platform)

**Date**: 2026-09-19  
**Platform**: macOS (Apple Silicon M1-M4 & Intel x86_64), DaVinci Resolve / Fusion Studio  
**Architecture**: Fusion DCTL Fuse (`.fuse`) + GPU DVIP Compute Node (Metal Backend)  

---

## 1. Architectural Choice & Rationale

We evaluated the two candidate architectures requested:

1. **Option A: Fusion DCTL Fuse (`.fuse`) - SELECTED**:
   - **Zero external dependencies**: Single-file plug-and-play installation into `~/Library/Application Support/Blackmagic Design/DaVinci Resolve/Fusion/Fuses/`.
   - **Native GPU Execution**: Runs on DaVinci's internal **DVIP Compute Engine**, which compiles directly to **Metal** compute pipelines on macOS with zero CPU-GPU copy bottlenecks.
   - **Universal Hardware Compatibility**: Works natively on all Apple Silicon generations (M1, M2, M3, M4) and legacy Intel Macs without binary cross-compilation or macOS Gatekeeper notarization hassles.
   - **Interactive Live Editing**: Multi-line `TextEditControl` in the Fusion Inspector allows real-time shader pasting, editing, and immediate visual update on the timeline.
   - **Timeline Integration**: Acts as a native `CT_SourceTool` Generator in Fusion and can be dragged directly onto the Edit Timeline via a Fusion Generator Template (`.setting`).

2. **Option B: OpenFX C++ Bundle (`.ofx.bundle`) - EVALUATED**:
   - Requires an external C++ build toolchain (CMake, Xcode, Apple Clang), SPIRV-Cross, glslang, and codesigning.
   - On modern macOS, unsigned or ad-hoc OFX bundles are frequently blocked by Gatekeeper.
   - Higher binary footprint (>30 MB) and increased crash risk if an unhandled GPU runtime exception occurs.

**Decision**: Implement **Option A** as the primary, robust, production-ready solution, with full source code, presets, templates, and comprehensive user guides.

---

## 2. System Architecture & Components

```
+-------------------------------------------------------------+
|                      DaVinci Resolve                        |
|   (Edit Timeline Generator / Fusion Composition Node)       |
+-------------------------------------------------------------+
                              |
                              v
+-------------------------------------------------------------+
|                     Shadertoy.fuse                          |
|  - FuRegisterClass("ShadertoyFuse", CT_SourceTool, ...)    |
|  - UI Controls: TextEditControl, Presets, Time/Mouse controls|
|  - Lua Preprocessor & GLSL normalizer                       |
+-------------------------------------------------------------+
                              |
                              v
+-------------------------------------------------------------+
|              DCTL / Metal Compatibility Header              |
|  - Types: vec2, vec3, vec4, mat2, mat3, ivec2, etc.         |
|  - Vector constructors: vec2(), vec3(), vec4() overloads     |
|  - Math Intrinsics: fract, mix, mod, clamp, smoothstep, etc.|
|  - Uniforms: iResolution, iTime, iTimeDelta, iFrame, iMouse |
+-------------------------------------------------------------+
                              |
                              v
+-------------------------------------------------------------+
|                    DVIP Compute Engine                      |
|  - Runtime compilation to Apple Metal Compute Pipeline      |
|  - Direct render to destination 32-bit floating point image |
+-------------------------------------------------------------+
                              |
                              v
+-------------------------------------------------------------+
|               Graceful Fallback & Diagnostics               |
|  - Compile error detection -> Magenta/Checkerboard display  |
|  - Console logging without crashing Resolve host            |
+-------------------------------------------------------------+
```

---

## 3. Shader Uniforms & Mapping

| Shadertoy Uniform | Type | Fusion / DCTL Origin | Description |
| :--- | :--- | :--- | :--- |
| `iResolution` | `vec3` | `params->iResolution` | Canvas width, height, and pixel aspect ratio (e.g. `(1920.0, 1080.0, 1.0)`) |
| `iTime` | `float` | `params->iTime` | Current playback time in seconds: `(frame / fps) * timeScale + timeOffset` |
| `iTimeDelta` | `float` | `params->iTimeDelta` | Duration of the current frame in seconds: `(1.0 / fps) * timeScale` |
| `iFrame` | `int` | `params->iFrame` | Current integer timeline frame number |
| `iMouse` | `vec4` | `params->iMouse` | `xy`: current cursor position in pixels; `zw`: click/drag coordinates |
| `iChannel0` | `__TEXTURE2D__` | `InChannel0` (optional) | Optional connected input texture/clip |

---

## 4. Error Handling & Stability Strategy

1. **Compilation Guard**:
   - The user shader is wrapped in a dedicated DCTL function called by `ShadertoyKernel`.
   - If `DVIPComputeNode` fails to build the pipeline, the Fuse intercepts the failure.
2. **Visual Fallback**:
   - Instead of showing a black frozen frame or crashing Resolve, the Fuse renders a diagnostic high-visibility pattern (magenta tint with soft grid / error indicator).
3. **Console Diagnostics**:
   - The Fuse logs compilation details to Resolve's Fusion Console (`Workspace -> Console`).

---

## 5. Preset Library Included

1. **Preset 1: Procedural Geometric Plasma (2D)**:
   - Dynamic trigonometric wave interference, vibrant color cycling, validating `iTime`, `iResolution`, `sin`, `cos`, `length`.
2. **Preset 2: 3D Raymarching SDF Sphere & Torus (3D)**:
   - Signed Distance Function (SDF) sphere with phong lighting, surface normals, diffuse + specular reflections, and interactive mouse orbiting via `iMouse`.
3. **Preset 3: Cyberpunk Neon Grid & Horizon**:
   - Retro futuristic neon grid with perspective vanishing point, glow, and pulsating synthwave horizon.
