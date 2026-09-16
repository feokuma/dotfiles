-- Wallpaper: start hyprpaper with its config (hyprpaper.conf).
-- The daemon handles preloading and assigning wallpapers to all monitors.
-- Swap images in ~/.config/hypr/hyprpaper.conf.

hl.on("hyprland.start", function()
    hl.exec_cmd("hyprpaper")
end)
