-- my3status plugin for showing the ALSA volume as a bar.
-- Requires "amixer" and possibly the en_US locale (FIXME).

local util = require("my3util")

local lastinst = -1
local mod = {
	--[[

	Parameters:
	* item: The ALSA item to query. Defaults to "Master".
	* barwidth: The width of the bar in characters. Defaults to 16.
	* fillsym: Symbol to print for a filled bar segment. Defaults to "#".
	* emptysym: Symbol to print for an empty bar segment. Defaults to " ".
	* prefix: Text to print before the bar. Defaults to "[".
	* postfix: Text to print after the bar. Defaults to "]".
	* colors: Table specifying colors for different values (see below).

	The color table is a table in the following format:
	{
		{ 0.5, util.colors.green },
		{ 0.75, util.colors.yellow },
		{ 1, util.colors.red },
	}

	The first value in each subtable is the maximum volume (in percent) for which the color will be
	used. The second value is the color to use. The subtables must be ordered ascending. The last
	entry must have a value of 1.

	]]
	new = function(cfg)
		cfg = cfg or {}
		assert(type(cfg) == "table")

		local item = cfg.item or "Master"
		local barwidth = cfg.barwidth or 16
		local fillsym = cfg.fillsym or "#"
		local emptysym = cfg.emptysym or " "
		local prefix = cfg.prefix or "🔊 ["
		local postfix = cfg.postfix or "]"
		local muteprefix = cfg.muteprefix or "🔇 ["
		local colors = cfg.colors or {
			{ 0.5, util.colors.green },
			{ 0.75, util.colors.yellow },
			{ 1, util.colors.red },
		}

		cfg = nil

		lastinst = lastinst + 1
		return {
			instance = lastinst,
			func = function()
				-- Extract max volume and current volume (native units, not percentages) from amixer
				-- TODO Don't ignore min volume
				local f = io.popen("amixer get \""..item.."\"")
				local min, max, vol, mutestr
				for line in f:lines() do
					if min == nil then
						min, max = line:match("Limits: Playback (%d+) %- (%d+)")
					end
					if vol == nil then
						vol, mutestr = line:match("Mono: Playback (%d+) .* %[(.*)%]")
					end
				end

				if min == nil or vol == nil then
					error("Unexpected amixer output")
				end

				local mute
				if mutestr == "on" then mute = false
				elseif mutestr == "off" then mute = true
				else error("Unexpected mute state "..mutestr) end

				-- Map vol to the range 0..max-min
				vol = vol - min
				max = max - min

				-- set vol to 0 on mute, because it still has the unmuted value
				local prefix = prefix
				if mute then
					vol = 0
					prefix = muteprefix
				end

				-- Calculate how full the bar should be drawn
				local percent = vol / max
				local barfill = percent * barwidth

				-- Find out what color to use
				local color = util.colorval(colors, percent)

				util.print(prefix, nil, false)

				-- "Render" the volume bar
				local str = ""
				for i = 1, barfill do
					str = str..fillsym
				end
				for i = barfill, barwidth-1 do
					str = str..emptysym
				end

				util.print(str, color, false)
				util.print(postfix)
			end,
			clickevent = function(...)
				-- Toggle mute on click
				os.execute("amixer set \""..item.."\" toggle > /dev/null 2>&1")
			end,
		}
	end,
}

return mod
