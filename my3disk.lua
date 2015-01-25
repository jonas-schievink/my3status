-- Shows disk usage as text

local util = require("my3util")

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
    * path - Mount point path that should be queried. Default is "/".

    Optional Parameters:
    * formatter - Lua function that formats its arguments "total", "used" and "avail".

    The string returned by `formatter` is printed directly, so it has to be formatted with
    `util.format`.

    ]]
    new = function(path, cfg)
        assert(type(path) == "string", "path must be a string (in new() of my3disk)")

        cfg = cfg or {}

        local formatter = cfg.formatter or function(total, used, avail)
            total = fmtspace(total)
            used = fmtspace(used)
            avail = fmtspace(avail)

            return util.format(used.." / "..total.." ("..avail.." free)")
        end

        return function()
            -- Query filesystem by running `df`
            local total, used, avail = querydisk(path)

            local rawstr = formatter(total, used, avail)
            util.printraw(rawstr)
        end
    end,

    -- Export "querydisk" function
    querydisk = querydisk,
    
    fmtspace = fmtspace,
}
