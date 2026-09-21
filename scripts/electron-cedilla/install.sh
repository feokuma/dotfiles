#!/usr/bin/env bash
# Instalador do fix de cedilha para Electron (adaptado de chromium-wayland-cedilla-fix).
# Instala o script de patch em /usr/local/bin + hook do pacman, e aplica o patch.
set -euo pipefail

# Pacote/binário alvo. Mude aqui quando o Electron do sistema mudar de versão
# (electron42 -> electron43, ...). O caminho padrão do Arch segue o padrão
# /usr/lib/electronXX/electron.
ELECTRON_VER="${ELECTRON_VER:-42}"
BIN="${BIN:-/usr/lib/electron${ELECTRON_VER}/electron}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ $EUID -ne 0 ]]; then
    echo "Este instalador precisa de root. Reexecutando com sudo..."
    exec sudo ELECTRON_VER="$ELECTRON_VER" BIN="$BIN" bash "$0" "$@"
fi

if [[ ! -f "$BIN" ]]; then
    echo "[erro] binário não encontrado: $BIN" >&2
    echo "Ajuste ELECTRON_VER (ex.: sudo ELECTRON_VER=43 ./install.sh) e tente novamente." >&2
    exit 1
fi

echo ">> Instalando script de patch em /usr/local/bin"
install -Dm755 "$SCRIPT_DIR/electron-cedilla-patch.py" /usr/local/bin/electron-cedilla-patch.py

echo ">> Instalando hook do pacman em /etc/pacman.d/hooks/electron${ELECTRON_VER}-cedilla.hook"
install -Dm644 "$SCRIPT_DIR/electron-cedilla.hook" "/etc/pacman.d/hooks/electron${ELECTRON_VER}-cedilla.hook"

echo ">> Aplicando patch agora ($BIN)"
python3 /usr/local/bin/electron-cedilla-patch.py "$BIN"

echo
echo "Feito. Feche completamente os apps Electron (VS Code etc.) e teste ' + c."
