-- Copy hovered/selected files to the Wayland clipboard as FILE URIs, so they
-- can be pasted into other applications (browsers, file managers) as files.
--
-- Requires wl-clipboard (`wl-copy`). URIs are `file://` + the absolute path,
-- percent-encoded per RFC 3986 (built character-wise, never by string
-- concatenation of raw paths). Two formats are offered:
--
--   * `text/uri-list` — the de-facto file-transfer format on X11/Wayland,
--     consumed by GTK/Qt apps and browsers; served by a long-running wl-copy
--     that owns the clipboard afterwards.
--   * `x-special/gnome-copied-files` — the GNOME/Nautilus flavor (first line
--     "copy"); wl-copy serves only one type per process, so the gnome variant
--     is started first with `--paste-once` (serves one paste request, then
--     exits) and the uri-list copy takes over clipboard ownership.
--
-- CRLF-terminated lines are used in the uri-list payload, as required by the
-- text/uri-list RFC.

local M = {}

local TITLE = "Clipboard"

local function notify(level, content)
	ya.notify { title = TITLE, content = content, timeout = 4, level = level }
end

--- RFC 3986 percent-encoding; `/` between segments must stay literal for the
--- URI to identify a filesystem path.
local function encode_uri_path(path)
	return (path:gsub("[^/~%w%-_%.%!%~%*%'%(%)]", function(char)
		return string.format("%%%02X", char:byte())
	end))
end

--- Snapshot target paths (selected files if any, otherwise the hovered
--- file). `cx` is only reachable inside a sync wrapper, which must be
--- defined at module scope and CALLED from the entry.
local snapshot_paths = ya.sync(function()
	local paths = {}
	local count = #cx.active.selected
	if count > 0 then
		for _, file in pairs(cx.active.selected) do
			paths[#paths + 1] = tostring(file.url)
		end
	else
		local hovered = cx.active.current.hovered
		if not hovered then
			return nil
		end
		paths[#paths + 1] = tostring(hovered.url)
	end
	return paths
end)

--- Start a wl-copy serving `mime_type` with `payload` on stdin.
--- Returns the Child, or nil after notifying about the failure.
local function spawn_wl_copy(mime_type, payload, paste_once)
	local args = { "--type", mime_type }
	if paste_once then
		args[#args + 1] = "--paste-once"
	end
	local child = Command("wl-copy"):arg(args):stdin(Command.PIPED):spawn()
	if child then
		child:write_all(payload)
	end
	return child
end

--- The keymap runs this async; the target list is fetched via `ya.sync`
--- because `cx` is sync-context-only, while the slow work (URI building,
--- spawning wl-copy) must happen in the async context.
function M:entry(job)
	if not job.args.files then
		notify("warn", "Unknown mode; pass --files")
		return
	end

	local paths = snapshot_paths()
	if not paths then
		notify("warn", "No file under the cursor")
		return
	end

	local uri_list = {}
	local gnome_lines = { "copy" }
	for _, path in ipairs(paths) do
		local uri = "file://" .. encode_uri_path(path)
		uri_list[#uri_list + 1] = uri .. "\r\n"
		gnome_lines[#gnome_lines + 1] = uri
	end

	local uri_payload = table.concat(uri_list)
	local gnome_payload = table.concat(gnome_lines, "\n") .. "\n"

	-- GNOME flavor first, leased for a single paste, so GTK apps that also
	-- query x-special/gnome-copied-files get it immediately.
	local gnome = spawn_wl_copy("x-special/gnome-copied-files", gnome_payload, true)
	if not gnome then
		notify("error", "Failed to start wl-copy (is wl-clipboard installed?)")
		return
	end

	-- Main copy: text/uri-list, serving the clipboard from now on.
	local copy = spawn_wl_copy("text/uri-list", uri_payload, false)
	if not copy then
		gnome:start_kill()
		notify("error", "Failed to start wl-copy (is wl-clipboard installed?)")
		return
	end

	local status = copy:wait()
	if not status or not status.success then
		gnome:start_kill()
		notify("error", "wl-copy exited with an error; clipboard unchanged")
		return
	end

	-- The GNOME one is --paste-once: it forks, serves a single paste request
	-- and exits on its own; reap it so no child handle lingers in the task.
	if gnome then
		pcall(function() gnome:wait() end)
	end

	notify("info", "Copied " .. #paths .. " file(s) to clipboard as URIs")
end

return M
