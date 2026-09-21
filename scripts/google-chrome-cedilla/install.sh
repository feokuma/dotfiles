#!/usr/bin/env bash
# Instalador do fix de cedilha para Google Chrome.
# ATENÇÃO: nas versões atuais (>= ~153) o Chrome já sincroniza ' + c -> ç
# upstream e este patch NÃO deve ser aplicado. Veja README.md.
# Este instalador existe para o caso de regressão em uma versão futura.
set -euo pipefail

BIN="${BIN:-/opt/google/chrome/chrome}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# o script de patch é o genérico compartilhado com o electron-cedilla
PATCH_SCRIPT="$SCRIPT_DIR/../electron-cedilla/electron-cedilla-patch.py"

if [[ $EUID -ne 0 ]]; then
    echo "Este instalador precisa de root. Reexecutando com sudo..."
    exec sudo BIN="$BIN" bash "$0" "$@"
fi

if [[ ! -f "$BIN" ]]; then
    echo "[erro] binário não encontrado: $BIN" >&2
    exit 1
fi

echo ">> Verificando se o patch é necessário..."
if ! python3 - "$BIN" <<'EOF'
import sys
data = open(sys.argv[1], "rb").read()
n = data.count(b"\x63\x00\x07\x01") + data.count(b"\x43\x00\x06\x01")
if n == 0:
    print("[ok] padrão c->ć/C->Ć não encontrado: esta versão do Chrome já é "
          "cedilha-correct. NÃO aplique o patch.")
    sys.exit(2)
print(f"[info] {n} alvo(s) de patch encontrado(s); prosseguindo.")
EOF
then
    # sai com sucesso sem patchar (não é um erro do instalador)
    exit 0
fi

echo ">> Instalando script de patch em /usr/local/bin"
install -Dm755 "$PATCH_SCRIPT" /usr/local/bin/electron-cedilla-patch.py

echo ">> Instalando hook do pacman em /etc/pacman.d/hooks/google-chrome-cedilla.hook"
install -Dm644 "$SCRIPT_DIR/google-chrome-cedilla.hook" /etc/pacman.d/hooks/google-chrome-cedilla.hook

echo ">> Aplicando patch agora ($BIN)"
python3 /usr/local/bin/electron-cedilla-patch.py "$BIN"

echo
echo "Feito. Feche o Chrome completamente e teste ' + c."
