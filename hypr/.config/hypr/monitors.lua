-- Monitors: explicit built-in panel plus a generic fallback for docking.
-- See https://wiki.hypr.land/Configuring/Core/Monitors/

-- Built-in panel (Samsung 2880x1800@120)
-- Explicit 0x0 so the Dell above (0x-1080) stays edge-aligned with it.
hl.monitor({
	output = "eDP-1",
	mode = "2880x1800@120",
	position = "0x0",
	scale = 1.5, --1.333333,
})

-- External Dell S2421HN (match by description, survives port changes on docking)
-- Placed directly above the built-in panel (laptop logical width is 1920 @1.5,
-- same as the Dell's 1920, so left edges line up at x=0).
hl.monitor({
	output = "desc:DELL S2421HN",
	mode = "1920x1080@74.97",
	position = "0x-1080",
	scale = 1,
})

-- Fallback for other external monitors: preferred mode, auto position
hl.monitor({
	output = "",
	mode = "preferred",
	position = "auto",
	scale = 1,
})
