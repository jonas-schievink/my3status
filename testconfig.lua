--[[

This is a test configuration that's used to test all available modules. Run it with `my3status.lua testconfig`.

The example config in `config.lua` serves as a reasonable default configuration and should not necessarily contain all modules.

]]

local util = require("my3util")
local volume = require("my3volume")
local datetime = require("my3datetime")
local cpu = require("my3cpu")
local disk = require("my3disk")
local diskbar = require("my3diskbar")

return {
    STATUS_CFG = {
        diskbar.new("/"),
        disk.new("/"),
        cpu.new(),
    	volume.new(),
    	datetime.new("%A, %d.%m.%Y %X"),
    },

    -- Delay in seconds between prints. Sub-second values are allowed.
    DELAY = 0.1,

    -- Set this to false to disable colored output
    ALLOW_COLOR = true,

    -- Outputs debugging info
    DEBUG = true,
}
