-- Shows disk usage as text

local util = require("util")

local spaceunits = { "K", "M", "G", "T", "P", "E" }

--[[

Formats the given kilobyte count. Converts and appends a suitable unit. The result is printed with
`decimals` digits after the decimal point (1 by default).

]]
local function fmtspace(kbytes, decimals)
    assert(type(kbytes) == "number")

    decimals = decimals or 1

    local unit = 1  -- 1 = kilo, 2 = mega, 3 = giga, ...
    while kbytes > 1024 do
        kbytes = kbytes / 1024
        unit = unit + 1
    end

    kbytes = string.format("%."..decimals.."f", kbytes)
    kbytes = kbytes.." "..spaceunits[unit].."iB"

    return kbytes
end

local function querydisk(path)
    local f = io.popen("df '"..path.."'", "r")

    f:read("*l")    -- dispose header
    local line = f:read("*l")
    f:close()
    f = nil

    local total, used, avail = line:match(".* (%d+)%s+(%d+)%s+(%d+)%s+%d+%%%s+")
    assert(total, "Unexpected `df` output")

    total = tonumber(total)
    used = tonumber(used)
    avail = tonumber(avail)

    return total, used, avail
end

return {
    --[[

    Required Parameters:
    * path - Mount point path that should be queried

    Optional Parameters:
    * formatter - Lua function that formats its arguments "total", "used" and "avail".
    * updatediv - The update frequency is divided by this to save CPU

    The string returned by `formatter` is printed directly, so it has to be formatted with
    `util.format`.

    ]]
    new = function(path, cfg)
        assert(type(path) == "string", "path must be a string")

        cfg = cfg or {}

        local updatediv = cfg.updatediv or 20
        local formatter = cfg.formatter or function(total, used, avail)
            total = fmtspace(total)
            used = fmtspace(used)
            avail = fmtspace(avail)

            return util.format(used.." / "..total.." ("..avail.." free)")
        end

        local updates = -1
        local total, used, avail
        return function()
            -- Update disk usage every `updatediv` updates
            updates = updates + 1
            if updates % updatediv == 0 then
                total, used, avail = querydisk(path)
            end

            local rawstr = formatter(total, used, avail)
            util.printraw(rawstr)
        end
    end,

    -- Export "querydisk" function
    querydisk = querydisk,

    fmtspace = fmtspace,
}
