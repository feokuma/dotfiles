#!/usr/bin/env bash
# Desinstalador do fix de cedilha para Google Chrome.
set -euo pipefail

BIN="${BIN:-/opt/google/chrome/chrome}"

if [[ $EUID -ne 0 ]]; then
    echo "Este desinstalador precisa de root. Reexecutando com sudo..."
    exec sudo BIN="$BIN" bash "$0" "$@"
fi

echo ">> Removendo hook do pacman"
rm -f /etc/pacman.d/hooks/google-chrome-cedilla.hook

# o script é compartilhado com electron-cedilla; só remova se nenhum hook
# do electron estiver instalado
if ! compgen -G '/etc/pacman.d/hooks/electron?-cedilla.hook' >/dev/null; then
    echo ">> Removendo script de patch (nenhum hook electron restante)"
    rm -f /usr/local/bin/electron-cedilla-patch.py
fi

if [[ -f "$BIN.orig" ]]; then
    echo ">> Removendo backups (.orig e .bak-*) de $BIN"
    rm -f "$BIN.orig" "$BIN".bak-*
fi

echo
echo "Feito. A reversão garantida do binário é reinstalar o pacote:"
echo "  yay -S google-chrome"
