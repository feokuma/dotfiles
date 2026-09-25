# clip-image.yazi

Copy the hovered file's **image content** (raw bytes) to the Wayland
clipboard with `wl-copy`, so it can be pasted directly into apps such as
browsers (Ctrl+V in Firefox/Chrome). Requires `wl-clipboard`.

The MIME type is detected with `file --brief --mime-type` — not from the
filename extension — and only `image/*` types are accepted; for anything
else the clipboard is left untouched. Directories are rejected.

## Usage

In `keymap.toml`:

```toml
[mgr]
prepend_keymap = [
	{ on = "<C-i>", run = "plugin clip-image -- --image", desc = "Copy image content to clipboard" },
]
```
