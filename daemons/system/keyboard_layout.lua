-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------
print("LOADING [DAEMONS system.keyboard_layout]: Getting awful, gears.[object, table]")
local awful = require("awful")
local gobject = require("gears.object")
local gtable = require("gears.table")
local string = string

print("LOADING [DAEMONS system.keyboard_layout]: Defining")
local keyboard_layout = { }
local instance = nil

local function new()
    local ret = gobject{}
    gtable.crush(ret, keyboard_layout, true)

    local dummy_keyboardlayout_widget = awful.widget.keyboardlayout()
    dummy_keyboardlayout_widget:connect_signal("widget::redraw_needed", function()
        ret:emit_signal("update", string.gsub(dummy_keyboardlayout_widget.widget.text:upper(), "%s+", ""))
    end)

    return ret
end

if not instance then
    print("LOADING [DAEMONS system.keyboard_layout]: No instance, calling new()")
    instance = new()
end

print("LOADING [DAEMONS system.keyboard_layout]: DONE")
return instance