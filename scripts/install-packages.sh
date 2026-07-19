#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${CONFIG_FILE:-"$SCRIPT_DIR/packages.conf"}"
AUR_HELPER="${AUR_HELPER:-yay}"
DRY_RUN=0
LIST_ONLY=0

usage() {
  cat <<'USAGE'
Uso:
  scripts/install-packages.sh [opcoes] [app ...]

Instala os pacotes necessarios para os dotfiles versionados neste repositorio.
Sem argumentos de app, instala todos os apps listados em scripts/packages.conf.
O grupo _base e sempre incluido.

Opcoes:
  -c, --config ARQUIVO     Usa outro manifesto de pacotes
  -n, --dry-run            Mostra os comandos sem executar
  -l, --list               Lista os apps conhecidos
      --aur-helper NOME    Helper AUR a usar (padrao: yay)
  -h, --help               Mostra esta ajuda

Exemplos:
  scripts/install-packages.sh
  scripts/install-packages.sh nvim zsh kitty
  scripts/install-packages.sh --dry-run hyprland waybar
USAGE
}

die() {
  printf 'erro: %s\n' "$*" >&2
  exit 1
}

run() {
  if (( DRY_RUN )); then
    printf '+'
    printf ' %q' "$@"
    printf '\n'
  else
    "$@"
  fi
}

bootstrap_yay() {
  if command -v yay >/dev/null 2>&1; then
    return 0
  fi

  if (( DRY_RUN )); then
    printf '+ tmp_dir=$(mktemp -d)\n'
    printf '+ git clone https://aur.archlinux.org/yay.git "$tmp_dir/yay"\n'
    printf '+ cd "$tmp_dir/yay"\n'
    printf '+ makepkg -si --needed\n'
    printf '+ rm -rf "$tmp_dir"\n'
    return 0
  fi

  local tmp_dir
  tmp_dir="$(mktemp -d)"
  trap 'rm -rf "$tmp_dir"' RETURN

  git clone https://aur.archlinux.org/yay.git "$tmp_dir/yay"
  (cd "$tmp_dir/yay" && makepkg -si --needed)
}

trim() {
  local value="$1"
  value="${value#"${value%%[![:space:]]*}"}"
  value="${value%"${value##*[![:space:]]}"}"
  printf '%s' "$value"
}

declare -A APP_MANAGERS=()
declare -A APP_PACKAGES=()
declare -a APP_ORDER=()

load_config() {
  [[ -f "$CONFIG_FILE" ]] || die "manifesto nao encontrado: $CONFIG_FILE"

  local line app manager packages
  while IFS= read -r line || [[ -n "$line" ]]; do
    line="${line%%#*}"
    line="$(trim "$line")"
    [[ -z "$line" ]] && continue

    IFS='|' read -r app manager packages <<< "$line"
    app="$(trim "${app:-}")"
    manager="$(trim "${manager:-}")"
    packages="$(trim "${packages:-}")"

    [[ -n "$app" && -n "$manager" && -n "$packages" ]] || die "linha invalida em $CONFIG_FILE: $line"
    [[ "$manager" == "pacman" || "$manager" == "aur" ]] || die "gerenciador invalido para $app: $manager"

    APP_ORDER+=("$app")
    APP_MANAGERS["$app"]="$manager"
    APP_PACKAGES["$app"]="$packages"
  done < "$CONFIG_FILE"
}

list_apps() {
  local app
  for app in "${APP_ORDER[@]}"; do
    [[ "$app" == "_base" ]] && continue
    printf '%s\n' "$app"
  done
}

append_packages() {
  local app="$1"
  local manager="${APP_MANAGERS[$app]}"
  local package

  for package in ${APP_PACKAGES[$app]}; do
    case "$manager" in
      pacman) PACMAN_PACKAGES+=("$package") ;;
      aur) AUR_PACKAGES+=("$package") ;;
    esac
  done
}

dedupe_array() {
  local -n input="$1"
  local -n output="$2"
  local item
  declare -A seen=()

  for item in "${input[@]}"; do
    if [[ -z "${seen[$item]:-}" ]]; then
      seen["$item"]=1
      output+=("$item")
    fi
  done
}

parse_args() {
  SELECTED_APPS=()

  while (($#)); do
    case "$1" in
      -c|--config)
        shift
        [[ $# -gt 0 ]] || die "informe o arquivo para --config"
        CONFIG_FILE="$1"
        ;;
      -n|--dry-run)
        DRY_RUN=1
        ;;
      -l|--list)
        LIST_ONLY=1
        ;;
      --aur-helper)
        shift
        [[ $# -gt 0 ]] || die "informe o helper para --aur-helper"
        AUR_HELPER="$1"
        ;;
      -h|--help)
        usage
        exit 0
        ;;
      --)
        shift
        while (($#)); do
          SELECTED_APPS+=("$1")
          shift
        done
        break
        ;;
      -*)
        die "opcao desconhecida: $1"
        ;;
      *)
        SELECTED_APPS+=("$1")
        ;;
    esac
    shift
  done
}

main() {
  parse_args "$@"
  load_config

  if (( LIST_ONLY )); then
    list_apps
    exit 0
  fi

  if ! command -v pacman >/dev/null 2>&1; then
    die "pacman nao encontrado; este script foi feito para Arch Linux"
  fi

  declare -a APPS_TO_INSTALL=("_base")
  if ((${#SELECTED_APPS[@]})); then
    APPS_TO_INSTALL+=("${SELECTED_APPS[@]}")
  else
    local app
    for app in "${APP_ORDER[@]}"; do
      [[ "$app" == "_base" ]] && continue
      APPS_TO_INSTALL+=("$app")
    done
  fi

  declare -a PACMAN_PACKAGES=()
  declare -a AUR_PACKAGES=()
  local app
  for app in "${APPS_TO_INSTALL[@]}"; do
    [[ -n "${APP_MANAGERS[$app]:-}" ]] || die "app nao listado no manifesto: $app"
    append_packages "$app"
  done

  declare -a UNIQUE_PACMAN_PACKAGES=()
  declare -a UNIQUE_AUR_PACKAGES=()
  dedupe_array PACMAN_PACKAGES UNIQUE_PACMAN_PACKAGES
  dedupe_array AUR_PACKAGES UNIQUE_AUR_PACKAGES

  if ((${#UNIQUE_PACMAN_PACKAGES[@]})); then
    run sudo pacman -S --needed "${UNIQUE_PACMAN_PACKAGES[@]}"
  fi

  if ((${#UNIQUE_AUR_PACKAGES[@]})); then
    if [[ "$AUR_HELPER" == "yay" ]]; then
      local has_yay=0
      local aur_package
      for aur_package in "${UNIQUE_AUR_PACKAGES[@]}"; do
        [[ "$aur_package" == "yay" ]] && has_yay=1
      done

      if (( has_yay )); then
        bootstrap_yay
      fi
    fi

    if ! command -v "$AUR_HELPER" >/dev/null 2>&1 && (( ! DRY_RUN )); then
      die "pacotes AUR solicitados (${UNIQUE_AUR_PACKAGES[*]}), mas '$AUR_HELPER' nao esta instalado"
    fi
    run "$AUR_HELPER" -S --needed "${UNIQUE_AUR_PACKAGES[@]}"
  fi
}

main "$@"
