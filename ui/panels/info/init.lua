-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------
local awful = require("awful")
local wibox = require("wibox")
local beautiful = require("beautiful")
local widgets = require("ui.widgets")
local helpers = require("helpers")
local dpi = beautiful.xresources.apply_dpi

local instance = nil

local path = ...
local calender = require(path .. ".calendar")
local weather = require(path .. ".weather")

local function new()
    return widgets.animated_panel {
        visible = false,
        ontop = true,
        minimum_width = dpi(800),
        maximum_width = dpi(800),
        minimum_height = dpi(600),
        maximum_height = dpi(600),
        axis = "y",
        start_pos = -500,
        placement = function(widget)
            awful.placement.top(widget, {
                honor_workarea = true,
                honor_padding = true,
                attach = true
            })
        end,
        shape = helpers.ui.rrect(),
        bg = beautiful.colors.background,
        widget = wibox.widget {
            widget = wibox.container.margin,
            margins = dpi(25),
            {
                layout = wibox.layout.flex.horizontal,
                spacing = dpi(15),
                calender,
                weather
            }
        }
    }
end

if not instance then
    instance = new()
end
return instance
