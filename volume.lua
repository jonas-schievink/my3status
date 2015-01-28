-- my3status plugin for showing the ALSA volume as a bar.
-- Requires "amixer" and possibly the en_US locale (FIXME).

local util = require("util")

return {
	--[[

	Parameters:
	* item: The ALSA item to query
	* barwidth: The width of the bar in characters
	* fillsym: Symbol to print for a filled bar segment
	* emptysym: Symbol to print for an empty bar segment
	* prefix: Text to print before the bar
	* muteprefix: Prefix to use when the channel is muted
	* postfix: Text to print after the bar
	* scrollvol: Increase/Decrease volume by this (raw value) by scrolling the mouse
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
		local scrollvol = cfg.scrollvol or 4
		local colors = cfg.colors or {
			{ 0.5, util.colors.green },
			{ 0.75, util.colors.yellow },
			{ 1, util.colors.red },
		}

		cfg = nil

		return {
			instance = util.geninst(),
			func = function()
				-- Extract max, min, current volume (as native units, not percentages)
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
				f:close()
				f = nil

				if min == nil or vol == nil then
					error("unexpected amixer output")
				end

				min = tonumber(min)
				assert(min, "unexpected amixer output: min is not a number")
				max = tonumber(max)
				assert(max, "unexpected amixer output: max is not a number")
				vol = tonumber(vol)
				assert(vol, "unexpected amixer output: volume is not a number")

				local mute
				if mutestr == "on" then mute = false
				elseif mutestr == "off" then mute = true
				else error("unexpected mute state "..mutestr) end

				-- set vol to min on mute, because it still has the unmuted value
				local prefix = prefix
				if mute then
					vol = min
					prefix = muteprefix
				end

				local pct = (vol-min) / (max-min)
				local color = util.colorval(colors, pct)

				util.print(prefix, nil, false)
				util.print(util.bar({
					pct = pct,
					width = barwidth,
					fillsym = fillsym,
					emptysym = emptysym,
				}), color, false)
				util.print(postfix)
			end,
			clickevent = function(e)
				--[[

				Mouse button codes:
				1 - Left
				2 - Middle
				3 - Right
				4 - Wheel up
				5 - Wheel down

				8 - Back
				9 - Forward

				]]

				local btntbl = {
					[1] = function()
						-- Toggle mute on left click
						os.execute("amixer -q set \""..item.."\" toggle")
					end,
					[4] = function()
						-- Increase volume when scrolling up
						os.execute("amixer -q set \""..item.."\" "..scrollvol.."+ unmute")
					end,
					[5] = function()
						-- Decrease volume when scrolling down
						os.execute("amixer -q set \""..item.."\" "..scrollvol.."- unmute")
					end,
				}

				local fn = btntbl[e.button]
				if fn then fn() end
			end,
		}
	end,
}
