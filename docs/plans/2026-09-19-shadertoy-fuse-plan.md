# DaVinci Resolve Shadertoy Generator Plugin Implementation Plan

> **For Antigravity:** REQUIRED WORKFLOW: Use `.agent/workflows/execute-plan.md` to execute this plan in single-flow mode.

**Goal:** Sviluppare un plugin Generatore nativo per DaVinci Resolve su macOS (Apple Silicon + Intel x86_64) per eseguire fragment shader Shadertoy in tempo reale nella pagina Fusion e nella Timeline di Edit.

**Architecture:** Fusion DCTL Fuse (`.fuse`) basato sull'engine GPU DVIP di DaVinci Resolve (compilatore runtime Metal su macOS) con header di emulazione GLSL, mappatura completa degli uniform Shadertoy (`iResolution`, `iTime`, `iTimeDelta`, `iFrame`, `iMouse`, `iChannel0`), interfaccia multiriga `TextEditControl`, fallback diagnostico robusto e template generator per la Edit Timeline.

**Tech Stack:** Lua, DaVinci Color Transform Language (DCTL), Apple Metal Compute Engine (DVIP), GLSL ES 3.0 compatibility layer, POSIX Shell.

---

### Task 1: Creazione dell'Header di Compatibilità GLSL -> DCTL/Metal

**Files:**
- Create: `Shadertoy_Header.h` (or embedded header within `Shadertoy.fuse`)

**Details:**
Definizione dei tipi GLSL (`vec2`, `vec3`, `vec4`, `ivec2`, `ivec3`, `ivec4`, `mat2`, `mat3`), costruttori e overloads a scalare singolo (`vec2(s)`, `vec3(s)`, `vec4(s)`), costruttori combinati (`vec3(vec2, z)`, `vec4(vec3, w)`), funzioni matematiche (`fract`, `mix`, `step`, `smoothstep`, `clamp`, `mod`, `length`, `normalize`, `dot`, `cross`, `reflect`, `atan`, etc.) e struttura parametri kernel `ShadertoyParams`.

---

### Task 2: Implementazione del Plugin Fusion Fuse (`Shadertoy.fuse`)

**Files:**
- Create: `Shadertoy.fuse`

**Details:**
1. Registrazione con `FuRegisterClass("ShadertoyFuse", CT_SourceTool, ...)` e `REG_TimeVariant = true`.
2. Controlli UI:
   - `InPreset`: Dropdown per selezione rapida preset.
   - `InCode`: `TextEditControl` a 24 righe per incollare e modificare codice GLSL.
   - `InTimeScale`, `InTimeOffset`, `InFrameOffset`: Controllo temporale animazione.
   - `InMouse` + `InMouseDown`: Coordinate cursore e click per `iMouse`.
   - `InChannel0`: Ingresso opzionale immagine per shader con texture.
   - `InStatus`: Etichetta di stato compilazione.
3. Logica in `Process(req)`:
   - Calcolo risoluzione, tempo `iTime`, delta `iTimeDelta`, frame `iFrame`, mouse `iMouse`.
   - Assemblaggio del kernel DCTL / Metal con l'header di compatibilità.
   - Esecuzione GPU tramite `DVIPComputeNode`.
   - Gestione errori con fallback visuale magenta/checkerboard e log in console.

---

### Task 3: Creazione degli Shader di Esempio e Presets

**Files:**
- Create: `examples/01_plasma_geometric.glsl`
- Create: `examples/02_raymarching_3d_sdf.glsl`
- Create: `examples/03_cyberpunk_neon_grid.glsl`

**Details:**
Tre shader testati e completi, formattati con firma standard `void mainImage(out vec4 fragColor, in vec2 fragCoord)`.

---

### Task 4: Creazione del Template per la Timeline di Edit (`Shadertoy.setting`)

**Files:**
- Create: `Shadertoy.setting`

**Details:**
Template macro per Fusion / Edit che inserisce il nodo `Shadertoy` collegato all'uscita `MediaOut1`, permettendo il drag & drop diretto da *Effetti -> Generatori* nella pagina Edit.

---

### Task 5: Script di Installazione e Makefile per macOS

**Files:**
- Create: `install.sh`
- Create: `Makefile`

**Details:**
Installatore automatico con rilevamento percorsi macOS, copia nei corretti percorsi di DaVinci Resolve (`Fusion/Fuses` e `Fusion/Templates/Edit/Generators`) e verifica permessi.

---

### Task 6: Documentazione e Manuale Utente Completo (User Guide)

**Files:**
- Create: `README.md`

**Details:**
Manuale utente esaustivo in lingua italiana:
- Guida passo-passo all'installazione su macOS.
- Uso nella pagina Fusion e nella Timeline di Edit.
- Guida all'adattamento del codice Shadertoy (uniforms, coordinate, `iChannel0`, multipass).
- Risoluzione dei problemi e diagnostica errori.
