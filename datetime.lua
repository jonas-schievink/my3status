-- Outputs the current date and time

local util = require("util")

return {
    --[[

    Required Parameters:
    * fmt - Formatting string passed to strftime

    ]]
    new = function(fmt)
        assert(type(fmt) == "string")
        
        return function()
            util.print(os.date(fmt))
        end
    end,
}
