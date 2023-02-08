-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------
local awful = require("awful")
local gtable = require("gears.table")
local wibox = require("wibox")
local pwidget = require("ui.widgets.popup")
local helpers = require("helpers")

local animated_popup = {
    mt = {}
}

local function fake_widget(image)
    return wibox.widget {
        widget = wibox.widget.imagebox,
        image = image
    }
end

function animated_popup:show()
    self.state = true

    self.screen = awful.screen.focused()
    self.minimum_height = awful.screen.focused().workarea.height
    self.maximum_height = awful.screen.focused().workarea.height

    local image = wibox.widget.draw_to_image_surface(self.real_widget, self.width, self.height)
    self.widget = fake_widget(image)
    self.animation.easing = helpers.animation.easing.outExpo
    self.visible = true
    if self.actual_pos == nil then
        self.actual_pos = self[self.axis]
    end
    self.animation:set(self.actual_pos)
    self:emit_signal("visibility", true)
end

function animated_popup:hide()
    if self.state == false then
        return
    end

    self.state = false

    local image = wibox.widget.draw_to_image_surface(self.widget, self.width, self.height)
    self.widget = fake_widget(image)
    self.animation.easing = helpers.animation.easing.inExpo
    self.animation:set(self.start_pos)
    self:emit_signal("visibility", false)
end

function animated_popup:toggle()
    if self.animation.state == true then
        return
    end
    if self.visible == false then
        self:show()
    else
        self:hide()
    end
end

local function new(args)
    args = args or {}

    local ret = pwidget(args)
    gtable.crush(ret, animated_popup, true)
    ret.axis = args.axis or "x"
    ret.start_pos = args.start_pos or 4000

    ret.state = false
    ret.real_widget = args.widget
    ret.animation = helpers.animation:new{
        pos = ret.start_pos,
        easing = helpers.animation.easing.outExpo,
        duration = 0.8,
        update = function(_, pos)
            ret[ret.axis] = pos
        end,
        signals = {
            ["ended"] = function()
                if ret.state == true then
                    ret.widget = ret.real_widget
                else
                    ret.visible = false
                end
            end
        }
    }

    return ret
end

function animated_popup.mt:__call(...)
    return new(...)
end

return setmetatable(animated_popup, animated_popup.mt)