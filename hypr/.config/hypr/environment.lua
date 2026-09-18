hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("GTK_IM_MODULE", "simple")
-- Force GTK apps (incl. portal file chooser used by Chrome) to follow dark theme
hl.env("GTK_THEME", "Adwaita-dark")

-- Session-wide editor: apps launched outside an interactive shell (e.g. yazi
-- spawned by the Quickshell launcher via `ghostty -e`) never read .zshrc,
-- so EDITOR must come from the compositor session env.
hl.env("EDITOR", "nvim")
hl.env("VISUAL", "nvim")
