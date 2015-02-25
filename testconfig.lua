--[[

This is a test configuration that's used to test all available modules.
Run it with `my3status.lua testconfig`.

The example config in `defaultconfig.lua` serves as a reasonable default configuration and should
not necessarily contain all modules.

]]

local util = require("util")
local volume = require("volume")
local datetime = require("datetime")
local cpu = require("cpu")
local disk = require("disk")
local diskbar = require("diskbar")
local mpd = require("mpd")

util.setdebug(true)
return {
    STATUS_CFG = {
        mpd.new(),
        diskbar.new("/"),
        disk.new("/"),
        cpu.new(),
    	volume.new(),
    	datetime.new("%A, %d.%m.%Y %X"),
    },

    -- Delay in seconds between prints. Sub-second values are allowed.
    DELAY = 0.5,

    -- Set this to false to disable colored output
    ALLOW_COLOR = true,
}
