-- Prints the CPU usage in percent

local util = require("my3util")

local mod = {
    --[[

    Parameters:
    * prefix: Text to print before the value
    * postfix: Text to print after the value

    ]]
    new = function(cfg)
        cfg = cfg or {}

        local prefix = cfg.prefix or "CPU: "
        local postfix = cfg.postfix or ""
        local colors = cfg.colors or {
            { 0.2, util.colors.blue },
            { 0.5, util.colors.green },
            { 0.75, util.colors.yellow },
            { 1, util.colors.red },
        }

        -- user, nice, system, idle, iowait, irq, softirq
        local last
        local delta

        local function read()
            local f = io.open("/proc/stat", "r")
            local line = f:read("*l")
            f:close()

            local values = {line:match("cpu  (%d+) (%d+) (%d+) (%d+) (%d+) (%d+) (%d+)")}
            if values == nil then error("Unexcpected /proc/stat output") end

            if last == nil then last = values end

            delta = {}
            for i, v in ipairs(values) do
                local cur, last = v, last[i]
                delta[i] = cur - last
            end

            last = values
        end

        return function()
            read()

            local total = 0
            for i = 1, #delta do
                total = total + delta[i]
            end

            -- Count all processes + irq + softirq towards "usage"
            local usage = delta[1] + delta[2] + delta[3] + delta[6] + delta[7]

            -- Ensure that pct is always valid
            local pct
            if total == 0 then pct = 0
            else pct = usage / total end
            if pct < 0 then pct = 0
            elseif pct > 1 then pct = 1 end

            local color = util.colorval(colors, pct)

            util.print(prefix, nil, false)
            -- EXERCISE 1: Explain what `postfix == ""` does in this context
            util.print(math.floor(pct * 100).."%", color, postfix == "")
            util.print(postfix)
        end
    end,
}

return mod
