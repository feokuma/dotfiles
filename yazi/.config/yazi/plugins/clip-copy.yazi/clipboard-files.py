#!/usr/bin/env python3
"""Hold files on the clipboard exactly like GNOME Files does.

Usage:
	clipboard-files.py FILE...

Serves, from ONE clipboard owner:
	* GTK4's native file-list clipboard (`Gdk.FileList`), which integrates
	  with the xdg-desktop-portal clipboard backend and carries the
	  application/vnd.portal.* tokens browsers use for file pastes
	* text/uri-list + x-special/gnome-copied-files (GNOME/Files flavor),
	  for clients that parse them directly

The process stays alive to serve paste requests, exactly like a file
manager does, and exits automatically when another application takes
ownership of the clipboard (or on SIGTERM).
"""

import argparse
import signal
import sys

import gi

gi.require_version("Gtk", "4.0")
from gi.repository import Gdk, Gio, GLib, Gtk  # noqa: E402
import urllib.parse  # noqa: E402

MIME_URI = "text/uri-list"
MIME_GNOME = "x-special/gnome-copied-files"


def build_byte_payloads(paths):
	uris = ["file://" + urllib.parse.quote(path) for path in paths]
	return {
		MIME_URI: "".join(uri + "\r\n" for uri in uris),
		# The Nautilus payload has no trailing newline after the last URI.
		MIME_GNOME: "copy\n" + "\n".join(uris),
	}


def main():
	parser = argparse.ArgumentParser(description=__doc__.split("\n", 1)[0])
	parser.add_argument("paths", nargs="+", help="absolute file paths to offer")
	args = parser.parse_args()

	Gtk.init()  # void; raises GError on failure in PyGI bindings

	providers = []

	# Native GTK4 file-list clipboard (portal-backed; the required piece for
	# pasting files into browsers).
	try:
		file_list = Gdk.FileList.new_from_array(
			[Gio.File.new_for_path(path) for path in args.paths]
		)
		providers.append(Gdk.ContentProvider.new_for_value(file_list))
	except Exception as exc:  # noqa: BLE001 — degrade to URIs-only clipboard
		sys.stderr.write(f"file-list provider unavailable: {exc}\n")

	# Direct-parse flavors for non-portal clients (Files managers, GTK).
	for name, text in build_byte_payloads(args.paths).items():
		payload = GLib.Bytes.new(text.encode())
		providers.append(Gdk.ContentProvider.new_for_bytes(name, payload))

	provider = Gdk.ContentProvider.new_union(providers)

	clipboard = Gdk.Display.get_default().get_clipboard()
	if not clipboard.set_content(provider):
		sys.stderr.write("clipboard set_content failed\n")
		return 1

	main_loop = GLib.MainLoop.new(None, False)
	signal.signal(signal.SIGTERM, lambda *_: main_loop.quit())

	# Ownership-loss detection: GDK4 releases our provider when another
	# application copies something; poll and die quietly to prevent stale
	# daemons from accumulating.
	def ownership_check():
		if clipboard.get_content() is None:
			main_loop.quit()
			return False  # stop the timeout
		return True  # keep polling

	GLib.timeout_add_seconds(2, ownership_check)

	main_loop.run()


if __name__ == "__main__":
	main()
