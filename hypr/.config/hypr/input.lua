-- Input: keyboard layout and laptop touchpad defaults.
-- See https://wiki.hypr.land/Configuring/Core/Devices/

hl.config({
	input = {
		kb_layout = "us",
		kb_variant = "intl",

		follow_mouse = 1,

		touchpad = {
			natural_scroll = true,
			tap_to_click = false,
			scroll_factor = 0.1,
		},
	},
})

hl.gesture({
	fingers = 3,
	direction = "horizontal",
	action = "workspace",
})
