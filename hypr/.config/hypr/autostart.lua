hl.on("hyprland.start", function()
    hl.exec_cmd("qs")
    -- Long-running idle/lock management daemon (see hypridle.conf).
    hl.exec_cmd("hypridle")
end)
