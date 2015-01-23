#!/bin/env lua

---------------------------------------------------------------------------------------------------
-- my3status is an i3status replacement written in Lua.
--
-- It supports loadable modules that can be chained together to get a status line that can be fed
-- to i3bar. my3status always outputs JSON.
---------------------------------------------------------------------------------------------------

-- Hard dependency on luaposix. Make sure to install.
local posix = require("posix")
local sig = require("posix.signal")
local poll = require("posix.poll")

-- Install signal handler for SIGUSR1. This allows sending SIGUSR1 to force a refresh
-- (like i3status)
sig.signal(sig.SIGUSR1, function() end)

-- Hack required to allow loading modules from ~/.i3/my3status/ (which isn't the working dir when
-- running with i3bar). FIXME
package.path = package.path..";"..os.getenv("HOME").."/.i3/my3status/?.lua"

-- Load my3util and the user config from the "hacked" path
local util = require("my3util")
local config = require("config")

util.setcolor(config.ALLOW_COLOR)

-- We need at least Lua 5.2
--
-- 5.3 would be fine as well, I think. But nobody uses it anyways, right?
assert(_VERSION == "Lua 5.2", "my3status requires Lua 5.2")


-- Maps instance IDs to instantiated module tables. For use with click events.
local instancemap = {}

local hasinput = false -- set to true after first line was read
local function handleinput()
	if not hasinput then
		hasinput = true
		assert(io.read("*l") == "[")	-- i3bar sends this as the first line, discard it
	end

	-- Read line of JSON, sacrifice a lamb, parse it
	local line = io.read("*l")

	-- BEWARE: This is not how you parse JSON. Do not parse JSON this way. You can't. It is
	-- mathematically impossible (literally). It's like "parsing" HTML with regex.

	-- Extract stuff out of the braces, but keep the closing one for reasons
	local inner = line:match("{(.+})")
	assert(inner)

	local obj = {}
	-- Parse JSON object fields  (with this self-explainatory pattern)
	for key, value in line:gmatch('"(%a+)":([^,}]+)[,}]') do
		if value:sub(1, 1) == "\"" then
			-- JSON string, extract it
			value = value:match("\"(.*)\"")
			assert(value)
			value = util.jsonunescape(value)
		else
			-- Assume number
			value = tonumber(value)
		end
		assert(value)

		obj[key] = value
	end

	-- If `instance` was specified, we can search for the module instance
	local instname = obj.instance
	if instname then
		local instance = instancemap[instname]
		assert(instance, "No module instance with name \""..instname.."\"")

		-- Call the module handler
		local handler = instance.clickevent
		if handler then handler(obj) end
	end
end

-- Main function. Starts sending JSON data to i3bar and queries all modules in a loop, building the
-- status line as configured
local function run()
	print('{"version":1, "click_events":true}')
	print("[[],")

	local typedispatch = {
		["string"] = function(str)
			-- Strings are written non-escaped. This allows use of "util.format" in status config.
			util.printraw(str)
		end,
		["function"] = function(f)
			-- Function created by some module. The function is responsible for outputting data,
			-- its return value is ignored.
			f()
		end,
		["table"] = function(t)
			-- "Full" module with an instance table. Allows to process i3 click events.
			local instance = tostring(t.instance)	-- instance identifier
			local func = t.func

			instancemap[instance] = t

			assert(type(instance) == "string" or type(instance) == "number")
			assert(type(func) == "function")

			util.setinst(instance)
			func()
			util.setinst(nil)
		end,
	}

	while true do
		util.printraw("[")
		util.printraw('{"full_text":"","separator":false,"separator_block_width":0}')

		for i, elem in ipairs(config.STATUS_CFG) do
			-- Output all configured status line elements
			local ty = type(elem)
			local f = typedispatch[ty]
			if f then f(elem)
			else error("Unknown status line element type: "..ty) end
		end

		util.printraw("],\n")
		util.flush()

		-- Wait until either the delay expires or i3bar (or someone else) sent something to stdin
		local res = poll.rpoll(0, config.DELAY * 1000)
		if res == 1 then
			-- i3bar sent an event
			handleinput()
		end
	end
end
run()
