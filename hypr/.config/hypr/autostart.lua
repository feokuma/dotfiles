hl.on("hyprland.start", function()
    -- XWayland apps read Xft.dpi from X resources; load it before launching apps
    -- (force_zero_scaling=true means X11 apps must scale themselves: 96 * 1.333333 ≈ 128)
    hl.exec_cmd("xrdb -merge ~/.Xresources")
    hl.exec_cmd("qs")
end)
