-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------
local beautiful = require("beautiful")
local naughty = require("naughty")
local picom_daemon = require("daemons.system.picom")
local helpers = require("helpers")

local icons = {"picom", "accessories-painting", "applications-painting", "azpainter", "com.github.wjaguar.mtpaint",
               "gnome-paint", "gpaint", "kolourpaint", "lazpaint", "mtpaint", "mypaint", "org.mypaint.MyPaint",
               "org.tuxpaint.Tuxpaint", "tuxpaint"}

picom_daemon:connect_signal("state", function(self, state)
    if helpers.ui.should_show_notification() == true then
        local text = state == true and "Enabled" or "Disabled"
        local font_icon = state == true and beautiful.icons.toggle.on or beautiful.icons.toggle.off

        naughty.notification {
            app_font_icon = beautiful.icons.spraycan,
            app_icon = icons,
            app_name = "Picom",
            font_icon = font_icon,
            icon = icons,
            title = "Picom",
            text = text
        }
    end
end)
