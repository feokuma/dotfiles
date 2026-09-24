#!/bin/sh
# Desabilita o touchpad do notebook enquanto QUALQUER mouse Bluetooth
# (Icon: input-mouse, via BlueZ) estiver conectado; reabilita quando não
# houver nenhum. Não depende de nomes amigáveis nem afeta outros
# dispositivos BT (fones, teclados).
#
# Event-driven: o `bluetoothctl --monitor` não reporta device connects
# (apenas ruído de controller/LE advertising), então o canal de eventos é o
# dbus-monitor no bus de sistema, filtrando os sinais
# org.bluez.Device1 Connected/Disconnected — emissores imediatos do BlueZ.
#
# Roda como unit systemd --user (bluetooth-touchpad.service), iniciada pelo
# autostart.lua em hyprland.start (Hyprland precisa estar rodando para o
# hyprctl funcionar). Logs via journal:
#   journalctl --user -u bluetooth-touchpad.service
#
# `--apply`: re-avaliação única (usado em config.reloaded, pois o reload de
# config Hyprland reseta o estado per-device do touchpad).

export PATH="/usr/bin:/usr/local/bin:/bin"

TOUCHPAD_NAME='asup1206:00-093a:300d-touchpad'
XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"

last_state=""

log() { printf '%s\n' "$*"; }

# hl.device per-device no Hyprland 0.55+ (Lua config).
touchpad_apply() {
  enable="$1"
  last_state="$enable"
  for path in "$XDG_RUNTIME_DIR/hypr"/*/; do
    [ -S "$path/.socket.sock" ] || continue
    sig="$(basename "$path")"
    if ! out="$(XDG_RUNTIME_DIR="$XDG_RUNTIME_DIR" \
        HYPRLAND_INSTANCE_SIGNATURE="$sig" hyprctl eval \
        "hl.device({name='$TOUCHPAD_NAME', enabled=$enable})" 2>&1)"; then
      printf 'touchpad-toggle: hyprctl eval falhou (inst=%s): %s\n' "$sig" "$out"
    else
      printf 'touchpad enabled=%s aplicado (%s)\n' "$enable" "$out"
    fi
  done
}

# Mhouses BT conectados: lista MACs cujo Icon do BlueZ é input-mouse.
count_mice() {
  mice=""
  for mac in $(bluetoothctl devices Connected 2>/dev/null | awk '{print $2}'); do
    icon="$(bluetoothctl info "$mac" 2>/dev/null | sed -n 's/^\s*Icon:[[:space:]]*//p' | tr -d '\r')"
    [ "$icon" = "input-mouse" ] || continue
    mice="$mice $mac"
  done
  printf '%s' "$mice"
}

recount() {
  mice="$(count_mice)"
  if [ -n "$mice" ]; then
    [ "$last_state" = "false" ] && return
    log "mouse BT conectado:$mice -> desabilita touchpad"
    touchpad_apply false
  else
    [ "$last_state" = "true" ] && return
    log "nenhum mouse BT conectado -> habilita touchpad"
    touchpad_apply true
  fi
}

# Modo --apply: re-avaliar uma vez (config.reloaded).
if [ "${1:-}" = "--apply" ]; then
  recount
  exit 0
fi

recount

# Eventos BlueZ: o connect chega como PropertiesChanged (interface
# org.freedesktop.DBus.Properties, sender org.bluez) e o disconnect como
# signal member=Disconnected. Match por interface+sender, filtrando na
# linha (matcher por member é inconsistente neste dbus-monitor).
# stdbuf: dbus-monitor bufferiza por bloco quando não tem tty.
stdbuf -oL dbus-monitor --system \
  "type='signal',sender='org.bluez',interface='org.bluez.Device1'" \
  "type='signal',sender='org.bluez',interface='org.freedesktop.DBus.Properties'" | while IFS= read -r line; do
  case "$line" in
    *"member=Disconnected"*|*"member=PropertiesChanged"*) recount ;;
  esac
done
