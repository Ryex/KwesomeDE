-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------
local gshape = require("gears.shape")
local gtable = require("gears.table")
local wibox = require("wibox")
local twidget = require("ui.widgets.text")
local beautiful = require("beautiful")
local dpi = beautiful.xresources.apply_dpi
local setmetatable = setmetatable
local capi = {
    root = root,
    mouse = mouse
}

local radio_group = {
    mt = {}
}

local function button(value, radio_group)
    local widget = wibox.widget {
         layout = wibox.layout.fixed.horizontal,
         id = value.id,
         spacing = dpi(15),
         {
             widget = wibox.widget.checkbox,
             id = "checkbox",
             forced_width = dpi(25),
             forced_height = dpi(25),
             shape = gshape.circle,
             color = value.color,
             check_color = value.check_color,
             paddings = dpi(2),
         },
         value.widget or {
             widget = twidget,
             size = 15,
             text = value.title,
             color = beautiful.colors.on_background
         }
     }

     local widget_to_connect = value.widget ~= nil and
        widget:get_children_by_id("checkbox")[1] or
        widget

     widget_to_connect:connect_signal("mouse::enter", function()
         capi.root.cursor("hand2")
         local wibox = capi.mouse.current_wibox
         if wibox then
             wibox.cursor = "hand2"
         end
     end)

     widget_to_connect:connect_signal("mouse::leave", function()
         capi.root.cursor("left_ptr")
         local wibox = capi.mouse.current_wibox
         if wibox then
             wibox.cursor = "left_ptr"
         end
     end)

     widget_to_connect:connect_signal("button::press", function(_, lx, ly, button, mods, find_widgets_result)
        if gtable.hasitem(mods, "Mod4") or button ~= 1 then
			return
		end

        radio_group:select(value.id)
     end)

     return widget
end

function radio_group:select(id)
    for _, value in ipairs(self._private.values) do
        local checkbox = value.button:get_children_by_id("checkbox")[1]
        if value.id == id then
            checkbox.checked = true
            if self._private.on_select then
                self._private.on_select(id)
            end
            self:emit_signal("select", id)
        else
            checkbox.checked = false
        end
    end
end

function radio_group:add_value(value)
    value.button = button(value, self)
    self._private.buttons_layout:add(value.button)
    table.insert(self._private.values, value)
end

function radio_group:remove_value(id)
    for index, value in ipairs(self._private.values) do
        if value.id == id then
            self._private.buttons_layout:remove_widgets(value.button)
            table.remove(self._private.values, index)
        end
    end
end

function radio_group:set_values(values)
    self._private.values = values

    for _, value in ipairs(values) do
        value.button = button(value, self)
        self._private.buttons_layout:add(value.button)
    end

    self:select(self._private.values[1].id)
end

function radio_group:get_values()
    return self._private.values
end

function radio_group:set_widget_template(widget_template)
    self:set_widget(widget_template)
    self._private.buttons_layout = widget_template:get_children_by_id("buttons_layout")[1]
end

function radio_group:set_on_select(on_select)
    self._private.on_select = on_select
end

local function new()
    local widget = wibox.container.background()
    gtable.crush(widget, radio_group, true)

    widget._private.values = {}

    return widget
end

function radio_group.horizontal()
    local widget = new()
    widget:set_widget_template(wibox.widget {
        layout = wibox.layout.fixed.horizontal,
        id = "buttons_layout",
        spacing = dpi(15),
    })
    return widget
end

function radio_group.vertical()
    local widget = new()
    widget:set_widget_template(wibox.widget {
        layout = wibox.layout.fixed.vertical,
        id = "buttons_layout",
        spacing = dpi(15),
    })
    return widget
end

function radio_group.mt:__call()
    return new()
end

return setmetatable(radio_group, radio_group.mt)
