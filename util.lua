-- Utility functions for my3status modules

local time = require("posix.time")

local allow_color = true
local dodebug = false

-- Writes the given objects to stderr if debugging is enabled.
local function debug(...)
	if not dodebug then return end

	io.stderr:write("[DEBUG]")

	local items = {...}
	for i, obj in ipairs(items) do
		if i == 1 then io.stderr:write(" ") end

		io.stderr:write(tostring(obj))

		if i < #items then io.stderr:write(", ") end
	end

	io.stderr:write("\n")
end

local function setdebug(d)
	dodebug = d
end

local function getdebug()
	return dodebug
end

-- Sleeps for the given time in seconds. This is done by invoking `sleep [time]`. If the system's
-- sleep command supports it, you can also pass non-integer values (allowing for sub-second sleep).
local function sleep(secs)
	assert(type(secs) == "number")

	local secs_int = math.floor(secs)
	local nsecs_int = math.floor((secs - secs_int) * 1000000000)

	time.nanosleep{ tv_sec = secs_int, tv_nsec = nsecs_int }
end

-- Checks that the given parameter `value` is of the correct type `exptype` or nil if `allownil` is
-- true. Outputs an error using the given parameter name in `name`.
local function checkparam(name, value, exptype, allownil)
	local ty = type(value)
	if exptype ~= ty then
		if allownil and value == nil then return end

		error("Parameter "..name.." of illegal type "..ty.." ("..exptype.." expected)")
	end
end

-- Escapes char sequences in the given string so that it can be wrapped in "" to become a valid
-- JSON string
local function jsonescape(str)
	return str:gsub("\"", "\\\""):gsub("\n", "\\n")
end

local function jsonunescape(str)
	return str:gsub("\\\"", "\""):gsub("\\n", "\n")
end

local instance

--[[

Sets the current instance name. The name is added to all outputs automatically and will be returned
by i3bar on click events.

]]
local function setinst(inst)
	instance = inst
end

-- Formats text as JSON output for sending to i3bar
local function format(text, color, separator, urgent)
	checkparam("text", text, "string")
	checkparam("color", color, "string", true)
	checkparam("separator", separator, "boolean", true)
	checkparam("urgent", urgent, "boolean", true)

	local str = ',{"full_text": "'..jsonescape(text)..'"'

	if color and allow_color then
		str = str..',"color":"'..jsonescape(color)..'"'
	end

	if separator == false then
		str = str..',"separator":false,"separator_block_width":0'
	end

	if urgent == true then
		str = str..',"urgent":true'
	end

	if instance then
		str = str..',"instance":"'..jsonescape(tostring(instance))..'"'
	end

	return str.."}"
end

local printbuf = ""

-- Appends the given raw string to the output buffer
local function printraw(str)
	printbuf = printbuf..str
end

-- Prints formatted JSON to the buffer
local function print(...)
	printraw(format(...))
end

-- Clears the output buffer and writes it to stdout
local function flush()
	io.write(printbuf)
	io.flush()
	printbuf = ""
end

local previnst = -1

--[[

Generate unique module instance string. Call in setup of module instances. For use with click
events.

]]
local function geninst()
	previnst = previnst + 1
	return tostring(previnst)
end

--[[

If `allow` is true, colors will be enabled, otherwise, colored output will have the default color.

]]
local function setcolor(allow)
	allow_color = allow
end

--[[

When given a color table and a value in the range 0..1, returns the color for the value as
defined in the color table. The color table has to look like this:

{
	{ 0.2, util.colors.red },
	{ 0.65, util.colors.yellow },
	{ 1, util.colors.green },
}

The first value in each subtable specifies the maximum value for which the specified color should
be used. The second value is the color string. The tables have to be ordered ascending and the last
table must have a value of 1.

This allows to define custom color schemes for all colorable values.

]]
local function colorval(colors, percent)
	assert(type(percent) == "number", "`percent` must be a number")
	assert(percent >= 0 and percent <= 1, "`percent` must be in the range 0..1")

	local color
	for i, coltbl in ipairs(colors) do
		assert(type(coltbl[1]) == "number", "color table entries must start with a number")
		assert(coltbl[1] > 0 and coltbl[1] <= 1, "color table values must be in range 0..1")
		assert(type(coltbl[2]) == "string", "color table entries must provide a color string")

		if percent <= coltbl[1] then
			color = coltbl[2]
			break
		end
	end
	assert(color, "invalid color table, no color for value "..percent)

	return color
end

--[[

Table for often used colors. Custom colors are always possible by using a string like "#aabbcc"

]]
local colors = {
	red = "#ff4444",
	green = "#44ff44",
	blue = "#4444ff",
	yellow = "#ffff44",
	purple = "#ff44ff",

	white = "#ffffff",
	black = "#000000",
}

--[[

Returns an ASCII bar that displays the given value.

Named Parameters:
* val - The value to draw as a bar
* min - The lower bound of the value
* max - The upper bound of the value
* width - The width of the bar in characters (assuming both fillsym and emptysym are one char wide)
* fillsym - The string to print for a filled bar segment
* emptysym - The string to print for an empty bar segment

]]
local function bar(tbl)
	local pct, width, fillsym, emptysym = tbl.pct, tbl.width, tbl.fillsym, tbl.emptysym

	assert(type(pct) == "number", "`pct` must be a number")
	assert(pct >= 0 and pct <= 1, "`pct` must be in range [0..1]")
	assert(type(width) == "number", "`width` must be a number")
	assert(fillsym, "parameter `fillsym` is required")
	assert(emptysym, "parameter `emptysym` is required")

	-- width units filled
	local fill = math.floor(pct * width)

	debug("util.bar", pct, fill, width)

	return fillsym:rep(fill)..emptysym:rep(width - fill)
end

local mod = {}
local function export(name, obj)
	assert(obj ~= nil, "Attempt to export nil (deleted an exported item?)")
	mod[name] = obj
end

export("debug", debug)
export("setdebug", setdebug)
export("getdebug", getdebug)
export("sleep", sleep)
export("checkparam", checkparam)
export("jsonescape", jsonescape)
export("jsonunescape", jsonunescape)
export("setinst", setinst)
export("format", format)
export("printraw", printraw)
export("print", print)
export("geninst", geninst)
export("flush", flush)
export("setcolor", setcolor)
export("colorval", colorval)
export("colors", colors)
export("bar", bar)

return mod
