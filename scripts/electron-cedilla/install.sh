#!/usr/bin/env bash
# Instalador do fix de cedilha para Electron (adaptado de chromium-wayland-cedilla-fix).
# Instala o script de patch em /usr/local/bin + hook do pacman, e aplica o patch.
#
# A versão do Electron é resolvida dinamicamente: o patch é aplicado a todos
# os binários /usr/lib/electron*/electron existentes, e o hook do pacman usa
# o glob "electron*" — sobrevive a upgrades de versão (electron42 -> electron43...).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOOK_NAME="electron-cedilla.hook"

if [[ $EUID -ne 0 ]]; then
    echo "Este instalador precisa de root. Reexecutando com sudo..."
    exec sudo bash "$0" "$@"
fi

if ! compgen -G '/usr/lib/electron*/electron' > /dev/null; then
    echo "[erro] nenhum binário /usr/lib/electron*/electron encontrado." >&2
    exit 1
fi

echo ">> Instalando script de patch em /usr/local/bin"
install -Dm755 "$SCRIPT_DIR/electron-cedilla-patch.py" /usr/local/bin/electron-cedilla-patch.py

# Remove hooks antigos fixados numa versão específica, se existirem
rm -f /etc/pacman.d/hooks/electron[0-9]*-cedilla.hook

echo ">> Instalando hook do pacman em /etc/pacman.d/hooks/${HOOK_NAME}"
install -Dm644 "$SCRIPT_DIR/electron-cedilla.hook" "/etc/pacman.d/hooks/${HOOK_NAME}"

echo ">> Aplicando patch agora (todos os /usr/lib/electron*/electron)"
python3 /usr/local/bin/electron-cedilla-patch.py

echo
echo "Feito. Feche completamente os apps Electron (VS Code etc.) e teste ' + c."
