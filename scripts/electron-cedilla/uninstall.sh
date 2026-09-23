#!/usr/bin/env bash
# Desinstalador do fix de cedilha para Electron.
# Remove o hook e o script; a reversão segura do binário é reinstalar o pacote.
set -euo pipefail

if [[ $EUID -ne 0 ]]; then
    echo "Este desinstalador precisa de root. Reexecutando com sudo..."
    exec sudo bash "$0" "$@"
fi

echo ">> Removendo hooks do pacman (atual e legados fixados por versão)"
rm -f /etc/pacman.d/hooks/electron-cedilla.hook /etc/pacman.d/hooks/electron[0-9]*-cedilla.hook

echo ">> Removendo script de patch"
rm -f /usr/local/bin/electron-cedilla-patch.py

echo ">> Removendo backups (.orig e .bak-*) de todos os /usr/lib/electron*/electron"
for dir in /usr/lib/electron*/; do
    [[ -d "$dir" ]] || continue
    if [[ -f "$dir/electron.orig" ]]; then
        rm -f "$dir/electron.orig" "$dir/electron".bak-*
    fi
done

echo
echo "Feito. A reversão garantida do binário é reinstalar o(s) pacote(s), ex.:"
echo "  sudo pacman -S electron43   # (ajuste conforme a versão instalada)"
