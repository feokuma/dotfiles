-- Input: keyboard layout and laptop touchpad defaults.
-- See https://wiki.hypr.land/Configuring/Core/Devices/

hl.config({
	input = {
		kb_layout = "us",
		kb_variant = "intl",

		follow_mouse = 1,

		touchpad = {
			natural_scroll = true,
			scroll_factor = 0.1,
			-- Firmware não reporta pressão/tamanho de contato, então libinput
			-- não consegue detectar palmas; DWT mitiga palmas enquanto digita.
			disable_while_typing = true,
			tap_to_click = false,
			-- Remove a área central do clickpad que emite clique do meio por
			-- posição; sem ela o meio exige LMB+RMB simultâneos.
			middle_button_emulation = true,
		},
	},
})

hl.gesture({
	fingers = 3,
	direction = "horizontal",
	action = "workspace",
})
