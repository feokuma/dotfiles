-- Input: keyboard layout and laptop touchpad defaults.
-- See https://wiki.hypr.land/Configuring/Core/Devices/

hl.config({
    input = {
        kb_layout  = "us",
        kb_variant = "intl",

        follow_mouse = 1,

        touchpad = {
            natural_scroll = true,
            tap_to_click   = false,
        },
    },
})

hl.gesture({
    fingers   = 3,
    direction = "horizontal",
    action    = "workspace",
})
