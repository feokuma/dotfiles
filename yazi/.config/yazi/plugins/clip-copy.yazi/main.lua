-- Copy hovered/selected files to the clipboard as FILES, so they can be
-- pasted into other applications (browsers, chats) as attachments,
-- mirroring a GNOME Files (Nautilus) copy.
--
-- Attempted wl-copy strategies before settling on this one (kept as part
-- of history for future revisits):
--   * two wl-copy processes do not stack types; each invocation OWNS the
--     clipboard, so the last one wins, leaving one flavor behind;
--   * a single persistent text/uri-list copy pastes NOTHING as a file in
--     Chromium (it only binds for drag-and-drop);
--   * a single persistent x-special/gnome-copied-files copy also does not
--     attach in Chromium.
-- What DOES work is what Nautilus does: a GTK4 clipboard source built from
-- a `Gdk.FileList`, which routes through the xdg-desktop-portal clipboard
-- backend and carries the `application/vnd.portal.*` handshake tokens.
-- That clipboard owner is a tiny detached helper daemon
-- (`clipboard-files.py` next to this plugin, talks GTK4 via PyGObject, no
-- extra packages), launched with `setsid` so it survives Yazi exiting and
-- does not hold a Yazi task open. It exits on its own when another app
-- takes clipboard ownership.

local M = {}

local TITLE = "Clipboard"

local function notify(level, content)
	ya.notify { title = TITLE, content = content, timeout = 4, level = level }
end

--- Snapshot target paths (selected files if any, otherwise the hovered
--- file). `cx` is only reachable inside a sync wrapper, defined at module
--- scope and CALLED from the entry.
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

--- The keymap runs this async; snapshot first via `ya.sync`, then detach
--- the helper.
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

--- Resolve the helper script path exactly as Yazi's loader would: config
--- dir honors YAZI_CONFIG_HOME, falling back to XDG_CONFIG_HOME and finally
--- `$HOME/.config`. (`debug` is not exposed in Yazi's Lua sandbox.)
local helper = (os.getenv("YAZI_CONFIG_HOME") or (
	(os.getenv("XDG_CONFIG_HOME") or (os.getenv("HOME") or "") .. "/.config") .. "/yazi"
)) .. "/plugins/clip-copy.yazi/clipboard-files.py"

	-- `setsid --fork` detaches: setsid itself exits immediately, the python
	-- daemon outlives Yazi and is NOT subject to Yazi's kill_on_drop.
	local sh = Command("setsid")
		:arg({ "--fork", "python3", helper })
		:arg(paths)
		:status()
	if not sh or not sh.success then
		notify("error", "Failed to start clipboard daemon (python3+GTK4 required)")
		return
	end

	notify("info", "Copied " .. #paths .. " file(s) to clipboard")
end

return M
