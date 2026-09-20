#!/usr/bin/env bash
# ==============================================================================
# Installer: Shadertoy Generator Plugin for DaVinci Resolve (macOS)
# Compatible with Apple Silicon (M1/M2/M3/M4) & Intel (x86_64)
# ==============================================================================

set -e

COLOR_GREEN="\033[0;32m"
COLOR_CYAN="\033[0;36m"
COLOR_YELLOW="\033[1;33m"
COLOR_RESET="\033[0m"

echo -e "${COLOR_CYAN}======================================================${COLOR_RESET}"
echo -e "${COLOR_CYAN}  DaVinci Resolve Shadertoy Generator Plugin Installer${COLOR_RESET}"
echo -e "${COLOR_CYAN}======================================================${COLOR_RESET}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RESOLVE_DIR="$HOME/Library/Application Support/Blackmagic Design/DaVinci Resolve"
FUSES_DIR="$RESOLVE_DIR/Fusion/Fuses"
TEMPLATES_GEN_DIR="$RESOLVE_DIR/Fusion/Templates/Edit/Generators"
TEMPLATES_EFF_DIR="$RESOLVE_DIR/Fusion/Templates/Edit/Effects"
FUSION_STUDIO_FUSES="$HOME/Library/Application Support/Blackmagic Design/Fusion/Fuses"

# 1. Check if DaVinci Resolve directory exists
if [ ! -d "$RESOLVE_DIR" ]; then
    echo -e "${COLOR_YELLOW}[!] Warning: DaVinci Resolve Application Support directory not found at:${COLOR_RESET}"
    echo "    $RESOLVE_DIR"
    echo "    Creating target directory tree..."
fi

# 2. Create destination directories
echo -e "\n[*] Configuring destination folders..."
mkdir -p "$FUSES_DIR"
mkdir -p "$TEMPLATES_GEN_DIR"
mkdir -p "$TEMPLATES_EFF_DIR"

# 3. Install Shadertoy.fuse
echo -e "[*] Installing Shadertoy.fuse -> $FUSES_DIR/Shadertoy.fuse"
cp -f "$SCRIPT_DIR/Shadertoy.fuse" "$FUSES_DIR/Shadertoy.fuse"
chmod 644 "$FUSES_DIR/Shadertoy.fuse"

# 4. Install Shadertoy.setting for Edit Timeline (Generators)
echo -e "[*] Installing Generator template -> $TEMPLATES_GEN_DIR/Shadertoy.setting"
cp -f "$SCRIPT_DIR/Shadertoy.setting" "$TEMPLATES_GEN_DIR/Shadertoy.setting"
chmod 644 "$TEMPLATES_GEN_DIR/Shadertoy.setting"

# 5. Install ShadertoyEffect.setting for Edit Timeline (Fusion Effects on video clips)
echo -e "[*] Installing Effect template -> $TEMPLATES_EFF_DIR/Shadertoy.setting"
cp -f "$SCRIPT_DIR/ShadertoyEffect.setting" "$TEMPLATES_EFF_DIR/Shadertoy.setting"
chmod 644 "$TEMPLATES_EFF_DIR/Shadertoy.setting"

# 6. Check Fusion Studio standalone (optional)
if [ -d "$HOME/Library/Application Support/Blackmagic Design/Fusion" ]; then
    mkdir -p "$FUSION_STUDIO_FUSES"
    cp -f "$SCRIPT_DIR/Shadertoy.fuse" "$FUSION_STUDIO_FUSES/Shadertoy.fuse"
    chmod 644 "$FUSION_STUDIO_FUSES/Shadertoy.fuse"
    echo -e "[*] Also installed for Fusion Studio standalone: $FUSION_STUDIO_FUSES"
fi

echo -e "\n${COLOR_GREEN}[✓] INSTALLATION COMPLETED SUCCESSFULLY!${COLOR_RESET}"
echo -e "------------------------------------------------------"
echo -e "Come usare il plugin in DaVinci Resolve:"
echo -e "1. Riavvia DaVinci Resolve per forzare la scansione dei template aggiornati."
echo -e "2. Pagina Fusion: premi Shift+Spazio, cerca 'Shadertoy' e aggiungi il nodo."
echo -e "3. Pagina Edit (Generatore): Effetti -> Generatori -> trascina 'Shadertoy' sulla Timeline."
echo -e "4. Pagina Edit (Effetto su Clip): Effetti -> Effetti -> trascina 'Shadertoy' direttamente su una clip video!"
echo -e "5. Se avevi già una vecchia clip 'Shadertoy' sulla Timeline, cancellala e trascinala di nuovo per caricare il nuovo Inspector."
echo -e "------------------------------------------------------"
