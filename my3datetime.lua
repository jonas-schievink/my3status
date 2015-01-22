-- Outputs the current date and time

local util = require("my3util")

local mod = {
    new = function(fmt)
        return function()
            util.print(os.date(fmt))
        end
    end,
}

return mod
