# DaVinci Resolve - Shadertoy Native GPU Generator Plugin (macOS)

Soluzione nativa ad alte prestazioni per eseguire fragment shader di **[Shadertoy](https://www.shadertoy.com)** direttamente all'interno di **DaVinci Resolve** e **Fusion Studio** su macOS (compatibile sia con **Apple Silicon M1/M2/M3/M4** che con architettura **Intel x86_64**).

Il plugin funziona come un **Generatore procedurale** sia all'interno del flusso nodale della **Pagina Fusion** sia come elemento trascinabile direttamente nella **Timeline della Pagina Edit**.

---

## 1. Architettura & Scelta Progettuale

Dopo un'approfondita valutazione tra le opzioni richieste:

- **OPZIONE A (Adottata): Fusion DCTL Fuse (`.fuse`)**
  - **Zero Dipendenze Binarie / Plug-and-Play**: Nessun bisogno di installare toolchain esterne pesanti (Xcode, CMake, glslang, SPIRV-Cross) o gestire i blocchi di sicurezza di macOS Gatekeeper per bundle `.ofx` non autenticati.
  - **Esecuzione GPU Nativa su Metal**: Utilizza il motore interno **DVIP Compute Engine** di DaVinci Resolve, che compila il kernel direttamente in pipeline di calcolo Metal sull'hardware Apple.
  - **Live Inspector Multiriga**: Interfaccia integrata con `TextEditControl` per incollare e modificare codice GLSL in tempo reale con aggiornamento istantaneo del fotogramma.
  - **Stabilità e Tolleranza ai Guasti**: Il runtime cattura gli errori di compilazione/sintassi senza causare il crash dell'applicazione ospite DaVinci Resolve, fornendo un fallback visivo diagnostico (colore magenta).

---

## 2. Specifiche Tecniche & Uniform Supportati

Il wrapper inietta automaticamente le variabili uniform standard di Shadertoy all'interno dello shader:

| Uniform | Tipo | Origine / Calcolo | Descrizione |
| :--- | :--- | :--- | :--- |
| `iResolution` | `vec3` | `params->iResolution` | Risoluzione del canvas (Larghezza in pixel, Altezza in pixel, Pixel Aspect Ratio). |
| `iTime` | `float` | `params->iTime` | Tempo corrente in secondi: `(CurrentFrame / FPS) * TimeSpeed + TimeOffset`. |
| `iTimeDelta` | `float` | `params->iTimeDelta` | Durata temporale del singolo fotogramma: `(1.0 / FPS) * TimeSpeed`. |
| `iFrame` | `int` | `params->iFrame` | Numero del fotogramma corrente sulla timeline. |
| `iMouse` | `vec4` | `params->iMouse` | Coordinate XY correnti del cursore in pixel; ZW coordinate di click/trascinamento. |
| `iChannel0` | `texture` | `InChannel0` (Input opzionale) | Canale texture di ingresso per collegare immagini o clip video esterne. |

Firma di ingresso compatibile al 100% con Shadertoy:
```glsl
void mainImage(out vec4 fragColor, in vec2 fragCoord);
```

---

## 3. Installazione su macOS

### Metodo A: Installazione Automatica con Script (Consigliato)

1. Apri il **Terminale** di macOS.
2. Posizionati nella cartella del progetto:
   ```bash
   cd /Users/mariosalvucci/Documents/Development/WEBDEV/_DAVINCI_TOY
   ```
3. Esegui lo script di installazione:
   ```bash
   ./install.sh
   ```
   Lo script creerà automaticamente le cartelle necessarie e copierà i file nei percorsi corretti.

---

### Metodo B: Installazione Manuale Passo-Passo

Se preferisci copiare i file manualmente tramite Finder o Terminale:

1. **Copia del Plugin Fuse (Pagina Fusion):**
   - **Cartella di destinazione:**
     `~/Library/Application Support/Blackmagic Design/DaVinci Resolve/Fusion/Fuses`
   - Copia il file `Shadertoy.fuse` all'interno di questa directory:
     ```bash
     mkdir -p "$HOME/Library/Application Support/Blackmagic Design/DaVinci Resolve/Fusion/Fuses"
     cp Shadertoy.fuse "$HOME/Library/Application Support/Blackmagic Design/DaVinci Resolve/Fusion/Fuses/"
     ```

2. **Copia del Template Generatore (Timeline Pagina Edit):**
   - **Cartella di destinazione:**
     `~/Library/Application Support/Blackmagic Design/DaVinci Resolve/Fusion/Templates/Edit/Generators`
   - Copia il file `Shadertoy.setting` all'interno di questa directory:
     ```bash
     mkdir -p "$HOME/Library/Application Support/Blackmagic Design/DaVinci Resolve/Fusion/Templates/Edit/Generators"
     cp Shadertoy.setting "$HOME/Library/Application Support/Blackmagic Design/DaVinci Resolve/Fusion/Templates/Edit/Generators/"
     ```

3. **Verifica dei Permessi:**
   Assicurati che i file siano leggibili dall'utente:
   ```bash
   chmod 644 "$HOME/Library/Application Support/Blackmagic Design/DaVinci Resolve/Fusion/Fuses/Shadertoy.fuse"
   chmod 644 "$HOME/Library/Application Support/Blackmagic Design/DaVinci Resolve/Fusion/Templates/Edit/Generators/Shadertoy.setting"
   ```

4. **Riavvia DaVinci Resolve** se era già aperto, in modo da consentire la scansione dei nuovi plugin.

---

## 4. Guida all'Uso dentro DaVinci Resolve

### Metodo 1: Nella Pagina Fusion (Massima Flessibilità Nodule)

1. Apri un progetto e portati nella pagina **Fusion**.
2. Premi `Shift + Spazio` (oppure cerca nei Tools di Fusion) e digita **`Shadertoy`**.
3. Seleziona lo strumento e premi **Add**. Apparirà il nodo `Shadertoy1`.
4. Collega l'uscita (`Output`, quadratino bianco) di `Shadertoy1` all'ingresso di `MediaOut1`:
   ```
   [ Shadertoy1 ] ---> [ MediaOut1 ]
   ```
5. Clicca sul nodo `Shadertoy1` per aprire l'**Inspector** a destra:
   - **Preset**: Seleziona tra i 3 preset integrati (Plasma, 3D Raymarching, Cyberpunk).
   - **Time Speed (iTime)**: Modifica la velocità di riproduzione (1.0 = normale, 0.5 = rallentatore, valori negativi = riproduzione all'indietro).
   - **Time Offset**: Sposta l'animazione temporale avanti o indietro di N secondi.
   - **Mouse Pos (iMouse.xy)**: Clicca e trascina il mirino sullo schermo per interagire con gli shader sensibili al mouse.
   - **GLSL Shader Code**: Incolla qui qualsiasi codice proveniente da Shadertoy!
6. Premi la barra spaziatrice per avviare la riproduzione in tempo reale.

---

### Metodo 2: Direttamente nella Timeline della Pagina Edit (Drag & Drop)

1. Apri la pagina **Edit** di DaVinci Resolve.
2. Apri il pannello **Effetti** in alto a sinistra.
3. Nel menu laterale, seleziona **Generators** (Generatori).
4. Individua il generatore denominato **`Shadertoy`**.
5. Trascinalo direttamente su una traccia video della tua Timeline come fosse una clip standard.
6. Seleziona la clip sulla timeline e apri l'**Inspector** in alto a destra:
   - Troverai tutti i controlli (Preset, Editor di codice, Controlli temporali e Mouse).
   - Ogni modifica viene renderizzata istantaneamente sulla traccia video!

---

## 5. Shader di Esempio Pronti all'Uso

All'interno della cartella `examples/` (e selezionabili dal menu Preset dell'Inspector) sono disponibili:

### 1. `examples/01_plasma_geometric.glsl` (Plasma 2D Procedurale)
- Dimostrazione di interferenza ondulatoria bidimensionale, formule trigonometriche multiple e color cycling fluido.
- Valida la reattività di `iTime`, `iResolution` e delle funzioni intrinseche `sin`, `cos`, `sqrt`, `length`.

### 2. `examples/02_raymarching_3d_sdf.glsl` (Raymarching 3D con Sfera e Toro)
- Rendering volumetrico raymarching (Sphere Tracing) di una sfera pulsante e un toro rotante in uno spazio tridimensionale.
- Include calcolo numerico delle normali di superficie, illuminazione Blinn-Phong (luce diffusa + speculare) e rotazione della telecamera reattiva al cursore `iMouse`.

### 3. `examples/03_cyberpunk_neon_grid.glsl` (Orizzonte Synthwave Anni '80)
- Tipica estetica retrò synthwave con sole sfumato a bande orizzontali, griglia prospettica a pavimento che scorre verso l'infinito e nebbia volumetrica all'orizzonte.

### 4. `examples/04_fractal_pyramid.glsl` (Piramide Frattale 3D Raymarching)
- Shader raymarching ricorsivo con rotazioni angolari dinamiche, estrazione distanze e palette cromatica procedurale.
- Valida la moltiplicazione tra vettori e matrici (`vec * mat`), la trasformazione di swizzle compound (`p.xz -= 0.5`) e la normalizzazione dei float.

### 5. `examples/05_texture_ripple_warp.glsl` (Deformazione Ondulatoria su iChannel0)
- Esempio di utilizzo dei canali di input: deforma e ondula in tempo reale qualsiasi immagine o video collegato a `iChannel0`.
- Include un pattern di test geometrico procedurale di fallback se nessun input è collegato.

### 6. `examples/06_crt_scanlines_glitch.glsl` (Monitor CRT Vintage & Aberrazione Cromatica)
- Trasforma il segnale video in ingresso su `iChannel0` in un display arcade vintage anni '80: curvatura dello schermo a barilotto, aberrazione cromatica sui bordi (separazione RGB), scanline orizzontali, vignettatura e flicker analogico.
- Include generatore di barre colore SMPTE di fallback se l'ingresso è vuoto.

---

## 6. Guida all'Adattamento del Codice da Shadertoy

La maggior parte degli shader standard di Shadertoy può essere incollata **senza alcuna modifica**. Il plugin implementa un'emulazione completa dell'ambiente Shadertoy:

### 1. Canali di Input Immagine / Video (`iChannel0`, `iChannel1`, `iChannel2`, `iChannel3`)
Il nodo `Shadertoy` dispone di **4 porte di ingresso immagine native** in Fusion:
- **`iChannel0`**: Ingresso principale (freccia arancione/oro sul nodo).
- **`iChannel1`**: Ingresso secondario (freccia verde sul nodo).
- **`iChannel2`** e **`iChannel3`**: Ingressi ausiliari.

**Come collegarli nel Flow di Fusion:**
- Trascina il filo da qualsiasi nodo (`MediaIn`, `Loader`, `Background`, `FastNoise`, o un altro `Shadertoy`) sul quadratino di ingresso del nodo `Shadertoy`.
- In alternativa, fai **click con il tasto destro** sul nodo `Shadertoy` o tieni premuto `Alt / Option` trascinando la connessione per selezionare a quale canale (`iChannel0`..`3`) collegare l'immagine!

### 2. Funzioni di Campionamento Texture Supportate
Nel tuo codice shader puoi usare tutte le consuete funzioni GLSL di Shadertoy:
- `texture(iChannelN, uv)`: Campiona il canale alle coordinate normalizzate `[0.0, 1.0]`.
- `texture(iChannelN, uv, bias)`: Campiona con livello di dettaglio / bias.
- `textureLod(iChannelN, uv, lod)`: Campiona specificando il livello MIP / LOD.
- `textureGrad(iChannelN, uv, dPdx, dPdy)`: Campiona con gradienti espliciti.
- `texelFetch(iChannelN, ivec2(px, py), lod)`: Campionamento a coordinate intere di pixel. Il plugin normalizza automaticamente le coordinate rispetto a `iChannelResolution`.
- `textureSize(iChannelN, lod)`: Restituisce un `ivec2` con larghezza e altezza del canale in pixel.
- `texture2D(...)` / `texture2DLod(...)`: Piena compatibilità all'indietro per shader WebGL 1.0 legacy.
- `textureCube(iChannelN, dir)` / `texture(iChannelN, dir)`: Proiezione sferica automatica su texture 2D / equirettangolari.

### 3. Variabili Globali Uniform dei Canali
- **`iChannelResolution[4]`**: Array di `vec3` contenente `{ larghezza, altezza, aspect ratio }` per ciascuno dei 4 canali. Se un canale non è collegato, utilizza la risoluzione del progetto per prevenire divisioni per zero.
- **`iChannelTime[4]`**: Tempo di riproduzione in secondi associato alla traccia video di ciascun canale.
- **`hasChannel0`..`hasChannel3`**: Flag booleani (1 o 0) disponibili internamente.

### 4. Impostazioni Avanzate di Risoluzione e Wrap (Inspector)
Nel gruppo **Channel Inputs & Textures** dell'Inspector puoi configurare:
- **Output Resolution**:
  - `Auto`: adatta la risoluzione di output all'immagine collegata su `iChannel0` (se presente), altrimenti usa la risoluzione della Timeline/Progetto.
  - `Match Timeline Resolution`: forza sempre la risoluzione della Timeline di DaVinci Resolve.
  - `Custom Resolution`: permette di impostare larghezza e altezza personalizzate (da 256x256 fino a 8K).
- **Wrap Mode per canale (0..3)**:
  - `Clamp to Edge`: i pixel ai bordi vengono estesi.
  - `Repeat / Wrap` (Predefinito): la texture si ripete all'infinito (`uv - floor(uv)`), ideale per pattern, rumore e texture piastrellabili.
  - `Mirrored Repeat`: la texture si ripete a specchio ad ogni bordo.

### 5. Shader Multipass (Buffer A, Buffer B, Buffer C, Buffer D)
Shadertoy usa i Buffer per simulazioni con persistenza temporale (fluidodinamica, sfocature progressive, riverbero luce).
In DaVinci Resolve, puoi replicare questa architettura collegando i nodi `Shadertoy` in cascata:
1. Crea un primo nodo `Shadertoy` con il codice del **Buffer A**.
2. Crea un secondo nodo `Shadertoy` con il codice del rendering finale (**Image**).
3. Collega l'uscita del primo nodo all'ingresso `iChannel0` del secondo nodo.
4. Per creare un anello di feedback (il fotogramma precedente re-immesso nel buffer):
   - Inserisci un nodo Fusion **Feedback** o **TimeSpeed** tra l'uscita e l'ingresso di `iChannel1` o `iChannel0`.

### 6. Contesto Unificato per Funzioni Fuori da `mainImage()`
Il Fuse incapsula automaticamente il codice utente all'interno di `struct ShadertoyContext`. Qualsiasi funzione ausiliaria (come `float map(vec3 p)`) può leggere direttamente `iTime`, `iResolution`, `iMouse`, `iChannelResolution` e campionare `texture(iChannel0, uv)` senza dover passare questi parametri manualmente come argomenti!

---

## 7. Risoluzione dei Problemi (Troubleshooting)

### Schermata Magenta / Fucsia Diagnostica
Se la schermata visualizza un colore magenta uniforme:
- Indica che il codice incollato contiene un **errore di sintassi** (ad esempio una parentesi mancante, una variabile non dichiarata o una funzione non supportata).
- **Come visualizzare l'errore esatto:**
  1. Nella barra dei menu superiore di DaVinci Resolve, vai su **Workspace -> Console** (oppure **Finestra -> Console**).
  2. Seleziona il tab **Fusion**.
  3. Troverai stampato il messaggio dettagliato del compilatore Metal di DaVinci Resolve con il numero di riga e la causa dell'errore.
  4. Correggi la riga nell'Inspector di `Shadertoy` e la visualizzazione si aggiornerà istantaneamente!

### Il plugin non compare nell'elenco di Fusion
- Verifica che `Shadertoy.fuse` si trovi esattamente in:
  `~/Library/Application Support/Blackmagic Design/DaVinci Resolve/Fusion/Fuses/`
- Ricorda che la cartella `Library` dell'utente è nascosta di default in macOS: puoi aprirla da Finder premendo `Cmd + Shift + G` e incollando il percorso completo.
- Riavvia DaVinci Resolve per forzare il refresh della cache dei plugin.
