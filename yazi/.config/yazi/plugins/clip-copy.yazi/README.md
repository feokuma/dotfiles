# clip-copy.yazi

Copy the hovered file (or all selected files) to the Wayland clipboard as
**file URIs** (`file://`, RFC 3986 percent-encoded), so they can be pasted
into other applications as files. Requires `wl-clipboard`.

Two formats are offered by two cooperating `wl-copy` processes (each
serves one MIME type only):

- `text/uri-list` (long-running clipboard owner, universal format).
- `x-special/gnome-copied-files` with a "copy" header, served once via
  `--paste-once` for the GTK/Nautilus flavor.

Requires yazi 26.x. Bound in `keymap.toml`:

```toml
[mgr]
prepend_keymap = [
	{ on = "<C-y>", run = "plugin clip-copy -- --files", desc = "Copy files to clipboard as URIs" },
]
```
