-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------
local awful = require("awful")
local beautiful = require("beautiful")
local ui_daemon = require("daemons.system.ui")

awful.screen.connect_for_each_screen(function(s)
    for i = 1, 8, 1  do
        awful.tag.add(i, {
            screen = s,
            layout = awful.layout.layouts[1],
            centered_layout_master_fill_policy = "master_width_factor",
            selected = i == 1 and true or false,
            font_icon = beautiful.taglist_icons[i],
            gap = ui_daemon:get_useless_gap(),
        })
    end
end)