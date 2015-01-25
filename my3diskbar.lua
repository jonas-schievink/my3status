-- Displays disk usage as a bar

local disk = require("my3disk")
local util = require("my3util")

return {
    new = function(path, cfg)
        cfg = cfg or {}

        local prefix = cfg.prefix or "["
        local postfix = cfg.postfix or "]"
        local barwidth = cfg.barwidth or 16
        local fillsym = cfg.fillsym or "#"
        local emptysym = cfg.emptysym or " "
        local nofree = cfg.nofree or false
        local updatediv = cfg.updatediv or 20
        local colors = cfg.colors or {
            { 0.8, util.colors.green },
            { 0.9, util.colors.yellow },
            { 1.0, util.colors.red },
        }

        local updates = -1
        local total, used, avail
        return function()
            -- Update disk usage every `updatediv` updates
            updates = updates + 1
            if updates % updatediv == 0 then
                total, used, avail = disk.querydisk(path)
            end

            local percent = used / total
            local col = util.colorval(colors, percent)
            local filled = percent * barwidth

            local bar = ""
            for i = 1, filled do
                bar = bar..fillsym
            end
            for i = filled, barwidth-1 do
                bar = bar..emptysym
            end

            util.print(prefix, nil, false)
            util.print(bar, col, false)
            util.print(postfix, nil, nofree)

            if not nofree then util.print(" "..disk.fmtspace(avail).." left") end
        end
    end,
}
