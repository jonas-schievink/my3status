-- Outputs the current date and time

local util = require("my3util")

return {
    --[[

    Required Parameters:
    * fmt - Formatting string passed to strftime

    ]]
    new = function(fmt)
        return function()
            util.print(os.date(fmt))
        end
    end,
}
