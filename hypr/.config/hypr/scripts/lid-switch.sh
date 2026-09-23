#!/usr/bin/env bash
# Lid switch handler, invoked from keybindings.lua ("switch:*:Lid Switch").
#
# closed, monitor externo presente:
#   desliga apenas o painel do laptop (eDP-1); o Hyprland migra os
#   workspaces dele para o monitor restante (comportamento nativo
#   testado com hl.monitor disabled). A sessão continua rodando —
#   suspend ainda é controlado pelos listeners do hypridle.
#
# closed, sem monitor externo:
#   lock + suspend (mesmo pipeline dos listeners do hypridle.conf).
#
# open: reativa o painel interno (no-op quando já está ligado).

case "$1" in
closed)
	monitor_count=$(hyprctl monitors | grep -c '^Monitor')
	if [ "$monitor_count" -gt 1 ]; then
		hyprctl eval 'hl.monitor({ output = "eDP-1", disabled = true })' >/dev/null
	else
		pidof hyprlock >/dev/null || hyprlock &
		sleep 0.5
		systemctl suspend
	fi
	;;
open)
	hyprctl eval 'hl.monitor({ output = "eDP-1", disabled = false })' >/dev/null
	;;
*)
	echo "usage: lid-switch.sh closed|open" >&2
	exit 1
	;;
esac
