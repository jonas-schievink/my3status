local volume = require("my3volume")
local datetime = require("my3datetime")
local cpu = require("my3cpu")

return {
    --[[

    Status line config. List of modules that are run on each update. Add fixed strings with
    util.format(text, color, separator, urgent) - for example:
    util.format("I'm red", util.colors.red)

    ]]
    STATUS_CFG = {
    	cpu.new(),
    	volume.new(),
    	datetime.new("%A, %d.%m.%Y %X"),
    },
    
    -- Delay in seconds between prints. Sub-second values are allowed.
    DELAY = 0.5,

    -- Set this to false to disable colored output
    ALLOW_COLOR = true,
}
