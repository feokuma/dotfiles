-- SVG previewer/preloader for Yazi.
--
-- Yazi ships a built-in `svg` previewer, but it depends on the `resvg` binary,
-- which is not installed on this system. This plugin does the same job using
-- `rsvg-convert` (librsvg, already installed). The name must NOT be "svg" —
-- that name resolves to the built-in preset plugin and shadows this one.
--
-- Flow: rasterize the SVG into Yazi's image cache (re-rendered only when the
-- source is newer than the cache), then render the PNG through the built-in
-- image previewer (`ya.image_show`), which uses the terminal's graphics
-- protocol (Kitty protocol on Ghostty).

local M = {}

local function rasterize(job, cache)
	local output, err = Command("rsvg-convert")
		:arg({ "-w", rt.preview.max_width, "-h", rt.preview.max_height, "-o", tostring(cache), tostring(job.file.url) })
		:status()
	if err then
		return err
	end
	if output and not output.success then
		return Err("rsvg-convert exited with code " .. tostring(output.code))
	end
end

-- A cached render is valid while it is at least as new as the source SVG.
local function is_fresh(cache, source)
	local cached = fs.cha(cache)
	local src = fs.cha(source)
	return cached and src and (cached.mtime or 0) >= (src.mtime or 0)
end

function M:peek(job)
	local cache = ya.file_cache(job)
	if not cache then
		return ya.preview_widget(job, Err("SVG preview unavailable for this file"))
	end

	if not is_fresh(cache, job.file.url) then
		local err = rasterize(job, cache)
		if err then
			return ya.preview_widget(job, err)
		end
	end

	local _, err = ya.image_show(cache, job.area)
	ya.preview_widget(job, err)
end

function M:seek() end

function M:preload(job)
	local cache = ya.file_cache(job)
	if not cache or is_fresh(cache, job.file.url) then
		return true
	end

	local err = rasterize(job, cache)
	if err then
		return false, err
	end
	return true
end

return M
