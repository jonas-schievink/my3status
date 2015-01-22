# my3status

Extensible i3status replacement written in Lua

# Features

## Integration into i3bar

`my3status` is meant to be used with i3bar. It is incompatible with other status bar applications, but that allows it to use i3bar-specific features like click events.

## Click Events

i3bar has support for "click events": When enabled, it will send messages to the `stdin` of the status line program that contain information about all clicks on my3status items. `my3status` supports these events and will dispatch them to the module that owns the clicked item (provided the module registered accordingly).

The builtin `my3volume` module is an example of this: You can toggle mute by clicking the volume bar and change the volume by scrolling the mouse wheel.

## Extensibility

Written in Lua, `my3status` enables its users to easily extend it with custom modules. Changes can be easily tested: Just reload i3. If debugging output is required, you can just run `./my3status.lua` and have it output JSON and debugging info to the terminal.

# Installation

Make sure Lua 5.2 is installed. Run `lua -v` to see your version.

You also need to install luaposix. Install the `luarocks` package from your favorite package manager, then run `sudo luarocks install luaposix`.

Then just clone this repo while in `~/.i3` (or copy all `.lua` files). `my3status` expects to be placed inside the directory `~/.i3/my3status`. If you prefer to have all git repositories in the same place, just create a symlink in `~/.i3`.

Now open your i3 config and replace the `status_command` of the `bar` section with `~/.i3/my3status/my3status.lua`. Restart i3 for the changes to take effects (Meta+Shift+R).

# Configuration

The configuration is done via `config.lua`. A simple default configuration is provided.

# Extension

You can easily write custom modules for `my3status`. The existing modules should serve as a good reference point, `my3volume.lua` even demonstrates the use of click events from i3bar.
