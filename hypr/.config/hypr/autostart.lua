hl.on("hyprland.start", function()
    hl.exec_cmd("qs")
    -- Long-running idle/lock management daemon (see hypridle.conf).
    hl.exec_cmd("hypridle")
    -- Desabilita o touchpad enquanto houver mouse BT conectado; inicia a
    -- unit systemd --user e reaplica o estado (reload de config reseta o
    -- estado per-device do touchpad).
    hl.exec_cmd("systemctl --user start bluetooth-touchpad.service")
    hl.exec_cmd("bluetooth-disable-touchpad.sh --apply")
end)

-- reload de config reseta o estado per-device do touchpad (enabled);
-- reavaliar imediatamente após cada reload.
hl.on("config.reloaded", function()
    hl.exec_cmd("bluetooth-disable-touchpad.sh --apply")
end)
