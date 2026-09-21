#!/usr/bin/env bash
# Desinstalador do fix de cedilha para Electron.
# Remove o hook e o script; a reversão segura do binário é reinstalar o pacote.
set -euo pipefail

ELECTRON_VER="${ELECTRON_VER:-42}"
BIN="${BIN:-/usr/lib/electron${ELECTRON_VER}/electron}"
PKG="electron${ELECTRON_VER}"

if [[ $EUID -ne 0 ]]; then
    echo "Este desinstalador precisa de root. Reexecutando com sudo..."
    exec sudo ELECTRON_VER="$ELECTRON_VER" BIN="$BIN" bash "$0" "$@"
fi

echo ">> Removendo hook do pacman"
rm -f "/etc/pacman.d/hooks/electron${ELECTRON_VER}-cedilla.hook"

echo ">> Removendo script de patch"
rm -f /usr/local/bin/electron-cedilla-patch.py

if [[ -f "$BIN.orig" ]]; then
    echo ">> Removendo backups (.orig e .bak-*) de $BIN"
    rm -f "$BIN.orig" "$BIN".bak-*
fi

echo
echo "Feito. A reversão garantida do binário é reinstalar o pacote:"
echo "  sudo pacman -S $PKG"
