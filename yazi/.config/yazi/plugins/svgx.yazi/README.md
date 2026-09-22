# svgx.yazi

SVG image preview for Yazi.

Yazi ships a built-in `svg` previewer, but it requires the `resvg` binary,
which is not installed on this system. This plugin does the same job with
`rsvg-convert` (librsvg).

**Important:** the plugin name must not be `svg` — the name `svg` resolves to
Yazi's built-in preset plugin, which shadows any user plugin of the same name.
This plugin is therefore named `svgx` (both the directory and the `run =`
reference in `yazi.toml`).

How it works: rasterizes the file with `rsvg-convert` into Yazi's image cache
(re-rendered only when the SVG is newer than the cache) and renders the PNG
through the built-in image previewer (`ya.image_show`), which uses whatever
graphics protocol the terminal supports (e.g. Kitty protocol in Ghostty).

Requires: `rsvg-convert` (Arch package `librsvg`).

If `resvg` is ever installed, this plugin and its `yazi.toml` rules can be
deleted — the built-in previewer takes over automatically.
