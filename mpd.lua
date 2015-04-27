-- Shows information about MPD (current track, etc.)
-- Requires the "mpc" tool for querying MPD from the command line

local util = require("util")

return {
    --[[

    Optional Parameters
    * host - If specified, queries MPD running on the given host instead of the local MPD
      (requires that MPD accepts network connections; watch out for latency!)
    * playprefix - Prefix to use when MPD is playing
    * pauseprefix - Prefix to use when MPD is paused
    * stopstr - String to print when no song is playing or paused
    * nompdstr - String to print when `mpc` encounters an error (ie. MPD isn't running)
    * formatter - Function that receives a table of values fetched from mpc; should print data in a
      suitable format

    ]]
    new = function(cfg)
        cfg = cfg or {}

        local host = cfg.host or false
        local playprefix = cfg.playprefix or "⏵ "
        local pauseprefix = cfg.pauseprefix or "⏸ "
        local stopstr = cfg.stopstr or "⏹ Not playing"
        local nompdstr = cfg.nompdstr or "MPD is not running!"
        local formatter = cfg.formatter or function(tbl)
            util.print(tbl.artist, "#aaaa00", false)
            util.print(" - ", nil, false)
            util.print(tbl.title, "#aaaa00", false)
            util.print(" (", nil, false)
            util.print(tbl.time, "#aa4444", false)
            util.print("/", nil, false)
            util.print(tbl.duration, "#aa4444", false)
            util.print(")")
        end

        -- Fields queried from MPC, available as format specifiers
        local separator = "~;_;~"
        local mpcfields = { "artist", "album", "albumartist", "composer", "date", "disc", "genre", "performer", "title", "track", "file" }

        local cmdline = "mpc -f '%"..table.concat(mpcfields, "%"..separator.."%").."%'"

        local function buildcmd(cmdline)
            if host then cmdline = cmdline.." -h '"..host.."'" end
            return cmdline
        end

        -- Matches the format string, used to extract the mpc fields
        local matchstr = "(.*)"..string.rep(separator.."(.*)", #mpcfields - 1)

        local function tobool(str)
            if str == "on" then return true elseif str == "off" then return false else
                error("invalid boolean value: '"..str.."'")
            end
        end

        return {
            func = function()
                local f = io.popen(buildcmd(cmdline), "r")
                local line = f:read("*l")

                util.debug(cmdline)

                -- mpc outputs one line when stopped or 3 when playing/paused and an error to
                -- stderr when the connection fails (ie. mpd isn't running). in the error case,
                -- nothing is printed to stdout, so line is nil
                if line ~= nil then
                    local mpcvals = {line:match(matchstr)}
                    if #mpcvals > 0 then
                        -- playing/paused
                        -- Parse second line

                        local pausestr, no, count, curtime, duration, pct = f:read("*l"):match("%[(.*)%]%s* #(%d+)/(%d+)%s* (.*)/(.*) %((%d+)%%%)")
                        assert(pausestr, "unexpected mpc output: couldn't parse line 2")

                        local paused
                        if pausestr == "paused" then
                            paused = true
                        elseif pausestr == "playing" then
                            paused = false
                        else
                            error("unexpected mpc output: invalid pause string '"..pausestr.."'")
                        end

                        local vol, rep, rnd, single, consume = f:read("*l"):match("volume:(.*)%s* repeat: (%w*)%s* random: (%w*)%s* single: (%w*)%s* consume: (%w*)%s*")
                        assert(rep, "unexpected mpc output: couldn't parse last line")

                        -- Convert everything to booleans
                        rep = tobool(rep)
                        rnd = tobool(rnd)
                        single = tobool(single)
                        consume = tobool(consume)

                        -- Build format table
                        local tbl = {}
                        for i = 1, #mpcfields do
                            tbl[mpcfields[i]] = mpcvals[i]
                        end

                        tbl["paused"] = paused
                        tbl["num"] = no
                        tbl["count"] = count
                        tbl["time"] = curtime
                        tbl["duration"] = duration
                        tbl["volume"] = vol
                        tbl["repeat"] = rep
                        tbl["random"] = rnd
                        tbl["single"] = single
                        tbl["consume"] = consume

                        util.print(paused and pauseprefix or playprefix, nil, false)
                        formatter(tbl)
                    else
                        -- stopped - no information available
                        util.print(stopstr)
                    end
                else
                    util.print(nompdstr)
                end
            end,
            clickevent = function(e)
                --[[

                Mouse button codes:
                1 - Left
                2 - Middle
                3 - Right
                4 - Wheel up
                5 - Wheel down

                8 - Back
                9 - Forward

                ]]

                local btntbl = {
                    [1] = function()
                        os.execute(buildcmd("mpc -q toggle"))
                    end,
                    [8] = function()
                        os.execute(buildcmd("mpc -q prev"))
                    end,
                    [9] = function()
                        os.execute(buildcmd("mpc -q next"))
                    end,
                }

                local fn = btntbl[e.button]
                if fn then fn() end
            end,
        }
    end,
}
