.PHONY: all install test uninstall

all: test

test:
	@echo "[*] Verifying Lua Fuse Syntax..."
	@/opt/homebrew/bin/luac -p Shadertoy.fuse
	@echo "[*] Running Test Suite..."
	@/opt/homebrew/bin/lua tests/test_preprocessor.lua
	@echo "[✓] All tests passed."

install:
	@bash ./install.sh

uninstall:
	@echo "[*] Removing Shadertoy files from DaVinci Resolve..."
	@rm -f "$$HOME/Library/Application Support/Blackmagic Design/DaVinci Resolve/Fusion/Fuses/Shadertoy.fuse"
	@rm -f "$$HOME/Library/Application Support/Blackmagic Design/DaVinci Resolve/Fusion/Templates/Edit/Generators/Shadertoy.setting"
	@echo "[✓] Uninstalled successfully."
