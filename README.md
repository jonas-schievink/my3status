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

## Force Update

Like `i3status`, you can force `my3status` to update itself by sending it the `USR1` signal. Execute this in your shell:

    pkill -USR1 -f 'lua.*my3status.lua'

Because the executing process is not `my3status.lua`, but the system's `lua`, we have to use `pkill` to match correctly. You *could* just use `killall -USR1 lua`, but that would send SIGUSR1 to all lua processes and because the default action is to terminate the program, this could end badly.

# Installation

Make sure Lua 5.2 is installed. Run `lua -v` to see your version.

You also need to install luaposix. Install the `luarocks` package from your favorite package manager, then run `sudo luarocks install luaposix`.

Then just clone this repo while in `~/.i3` (or copy all `.lua` files to `~/.i3/my3status`). `my3status` expects to be placed inside the directory `~/.i3/my3status`. If you prefer to have all git repositories in the same place, just symlink the directory to `~/.i3`.

Now open your i3 config and replace the `status_command` of the `bar` section with `~/.i3/my3status/my3status.lua`. Restart i3 for the changes to take effects (Meta+Shift+R).

# Configuration

The configuration is done via `config.lua`. A simple default configuration is provided.

## Custom Colors

The `my3util` module provides a `colorval` function that takes a color table and a value in the range 0..1 and returns the color the value should be displayed in as specified in the table. Modules that support colors will provide a sensible default table, and may additionally allow custom colors via a configuration parameter.

Example color table:

```lua

{
    { 0.2, util.colors.red },
    { 0.5, util.colors.yellow },
    { 0.75, util.colors.green },
    { 1, util.colors.blue },
}

```

This table specifies that a value <= 0.2 should be printed in red, a value <= 0.5 in yellow, a value <= 0.75 in green, and all remaining values (<= 1) in blue.

All color tables must be sorted ascending. The last entry must specify a value of 1.

# Extension

You can easily write custom modules for `my3status`. The existing modules should serve as a good reference point, `my3volume.lua` even demonstrates the use of click events from i3bar.

The `my3util` module provides utility functions that should be used by my3status modules. See other modules for usage hints or `my3util.lua` for some documentation.

# TODOs

* Remove `util.geninst()` from modules. The ID is only used to dispatch input events, so this should be done internally by my3status.
* Allow overriding any module's input event handler. This allows, for example, launching an MPD client when middle-clicking on the MPD module.
