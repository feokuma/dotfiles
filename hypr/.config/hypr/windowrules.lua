-- Window rules (see https://wiki.hypr.land/Configuring/Core/Rules/)

hl.window_rule({
    -- Ignore maximize requests from all apps. You'll probably like this.
    match = { class = ".*" },

    suppress_event = "maximize",
})

hl.window_rule({
    -- Fix some dragging issues with XWayland
    name = "fix-xwayland-drags",
    match = {
        class      = "^$",
        title      = "^$",
        xwayland   = true,
        float      = true,
        fullscreen = false,
        pin        = false,
    },

    no_focus = true,
})

hl.window_rule({
    -- GTK portal dialogs (file chooser) open huge; keep them modest and centered.
    -- Match both spellings: native Wayland uses lowercase, XWayland-parented
    -- dialogs (e.g. Chrome running under --ozone-platform=x11) use capitalized.
    name = "portal-dialogs-size",
    match = { class = "^[Xx]dg-desktop-portal-gtk$" },

    float = true,
    size = { 1100, 650 },
    center = true,
})

hl.window_rule({
    -- Satty (screenshot editor) should always open as a floating window.
    name = "satty-float",
    match = { class = "com.gabm.satty" },

    float = true,
})

hl.window_rule({
    -- Any window that becomes floating (e.g. via SUPER+F) opens small and
    -- centered. The `float` matcher reacts to the floating state, so it also
    -- applies to windows floated dynamically after opening.
    name = "floating-small-centered",
    match = { float = true, fullscreen = false },

    size = { "(monitor_w*0.6)", "(monitor_h*0.6)" },
    center = true,
})
