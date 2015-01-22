# my3status

Extensible i3status replacement written in Lua

# Installation

Make sure Lua 5.2 is installed. Run `lua -v` to see your version.

You also need to install luaposix. Install the `luarocks` package from your favorite package manager, then run `sudo luarocks install luaposix`.

Then just clone this repo while in `~/.i3` (or copy all `.lua` files). `my3status` expects to be run inside the directory `~/.i3/my3status`. If you prefer to have all git repositories in the same place, just create a symlink in `~/.i3`.

Now open your i3 config and replace the `status_command` of the `bar` section with `~/.i3/my3status/my3status.lua`. DONE! Restart i3 for the changes to take effects (Meta+Shift+R)
