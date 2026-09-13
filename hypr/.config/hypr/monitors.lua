-- Monitors: explicit built-in panel plus a generic fallback for docking.
-- See https://wiki.hypr.land/Configuring/Core/Monitors/

-- Built-in panel (Samsung 2880x1800@120)
hl.monitor({
    output   = "eDP-1",
    mode     = "2880x1800@120",
    position = "auto",
    scale    = 1.333333,
})

-- Fallback for external monitors / undocked states
hl.monitor({
    output   = "",
    mode     = "preferred",
    position = "auto",
    scale    = 1,
})
