-- Copy the hovered image's CONTENT (bytes) to the Wayland clipboard.
--
-- Requires wl-clipboard (`wl-copy`). MIME is detected with
-- `file --brief --mime-type` (never the filename extension) and only
-- `image/*` is accepted: directories (reported as `inode/directory`) and
-- any non-image are rejected without touching the clipboard. `-L` follows
-- symlinks, so broken or directory links are rejected as well.
--
-- Bytes are streamed into wl-copy's stdin in bounded Lua chunks, so exactly
-- one child (`wl-copy`) lives under Yazi's scheduler and is reaped via
-- `wait()` before the task completes — no half-open chained `cat` pipe.
--
-- `ya.sync(fn)` returns a synchronous WRAPPER FUNCTION captured at load
-- time; it must be defined it at module scope and CALLED from the entry,
-- not returned from a local helper.

local M = {}

local TITLE = "Clipboard"
local CHUNK = 64 * 1024

local function notify(level, content)
	ya.notify { title = TITLE, content = content, timeout = 4, level = level }
end

-- Capture the hovered file's path synchronously at plugin invocation time.
local get_hovered = ya.sync(function()
	local hovered = cx.active.current.hovered
	if not hovered then
		return nil
	end
	return tostring(hovered.url)
end)

--- The heavy work (file detection, wl-copy) runs in the async ctx.
function M:entry(job)
	if not job.args.image then
		notify("warn", "Unknown mode; pass --image")
		return
	end

	local path = get_hovered()
	if type(path) ~= "string" or path == "" then
		notify("warn", "No file under the cursor")
		return
	end

	local output, mime_err = Command("file")
		:arg({ "--brief", "-L", "--mime-type", "--", path })
		:output()
	local mime = output and output.stdout and output.stdout:gsub("%s+$", "") or ""
	if not output or not output.status.success or mime == "" then
		notify("error", "Failed to detect file type" .. (mime_err and (": " .. tostring(mime_err)) or ""))
		return
	end

	if not mime:match("^image/") then
		-- Includes directories (`inode/directory`) and symlink-to-dir cases.
		notify("warn", "Not an image (" .. mime .. "); clipboard unchanged")
		return
	end

	-- Feed wl-copy's stdin in bounded chunks.
	local copy = Command("wl-copy"):arg({ "--type", mime }):stdin(Command.PIPED):spawn()
	if not copy then
		notify("error", "Failed to start wl-copy (is wl-clipboard installed?)")
		return
	end

	local src = io.open(path, "rb")
	if not src then
		copy:start_kill()
		notify("error", "Failed to open " .. path)
		return
	end

	while true do
		local chunk = src:read(CHUNK)
		if not chunk or chunk == "" then
			break
		end
		local ok, werr = copy:write_all(chunk)
		if not ok then
			src:close()
			copy:start_kill()
			notify("error", "Failed to feed wl-copy: " .. tostring(werr))
			return
		end
	end
	src:close()

	local status = copy:wait()
	if not status or not status.success then
		notify("error", "wl-copy exited with an error; clipboard unchanged")
		return
	end

	notify("info", "Copied image to clipboard as " .. mime)
end

return M
