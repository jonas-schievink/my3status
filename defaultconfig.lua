local util = require("util")
local volume = require("volume")
local datetime = require("datetime")
local cpu = require("cpu")
local diskbar = require("diskbar")
local mpd = require("mpd")

return {
    --[[

    Status line config. List of modules that are run on each update. Add fixed strings with
    util.format(text, color, separator, urgent) - for example:
    util.format("I'm red", util.colors.red)

    Some modules take (optional) parameters. Look into the module file for information.

    ]]
    STATUS_CFG = {
        diskbar.new("/"),
    	cpu.new(),
    	volume.new(),
    	datetime.new("%A, %d.%m.%Y %X"),
    },

    -- Delay in seconds between prints. Sub-second values are allowed.
    DELAY = 0.5,

    -- Set this to false to disable colored output
    ALLOW_COLOR = true,
}
