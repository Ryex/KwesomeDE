local wibox = require("wibox")
local widgets = require("ui.widgets")
local slider_text_input = require("ui.apps.settings.slider_text_input")
local checkbox = require("ui.apps.settings.checkbox")
local picker = require("ui.apps.settings.picker")
local separator = require("ui.apps.settings.separator")
local beautiful = require("beautiful")
local ui_daemon = require("daemons.system.ui")
local dpi = beautiful.xresources.apply_dpi
local setmetatable = setmetatable

local ui = {
    mt = {}
}

local function checkbox_widget(key, title)
    local widget = checkbox {
        title = title,
        state = ui_daemon["get_" .. key](ui_daemon),
        on_turn_on = function()
            ui_daemon["set_" .. key](ui_daemon, true)
        end,
        on_turn_off = function()
            ui_daemon["set_" .. key](ui_daemon, false)
        end
    }

    return widget
end

local function slider(title, initial_value, maximum, round, on_changed, minimum, signal)
    local widget = slider_text_input {
        title = title,
        round = round,
        value = initial_value,
        minimum = minimum or 0,
        maximum = maximum,
        on_changed = on_changed
    }

    if signal then
        ui_daemon:connect_signal(signal, function(self, value)
            widget:get_slider_text_input():set_value(tostring(value))
        end)
    end

    return widget
end

local function new()
    return wibox.widget {
        layout = wibox.layout.overflow.vertical,
        scrollbar_widget = widgets.scrollbar,
        scrollbar_width = dpi(10),
        step = 50,
        spacing = dpi(15),
        picker.file {
            title = "Profile image:",
            initial_value = ui_daemon:get_profile_image(),
            on_changed = function(text)
                ui_daemon:set_profile_image(text)
            end
        },
        separator(),
        {
            layout = wibox.layout.fixed.vertical,
            forced_height = dpi(60),
            spacing = dpi(5),
            slider("DPI:", ui_daemon:get_dpi(), 250, true, function(value)
                ui_daemon:set_dpi(value)
            end),
            {
                widget = widgets.text,
                italic = true,
                size = 10,
                text = "* Restart AwesomeWM for this to take effect"
            }
        },
        separator(),
        slider("Useless gap:", ui_daemon:get_useless_gap(), 250, true, function(value)
            ui_daemon:set_useless_gap(value)
        end, 0, "useless_gap"),
        slider("Client gap:", ui_daemon:get_client_gap(), 250, true, function(value)
            ui_daemon:set_client_gap(value)
        end, 0, "client_gap"),
        separator(),
        slider("Opacity:", ui_daemon:get_opacity(), 1, false, function(value)
            ui_daemon:set_opacity(value)
        end),
        slider("Corner Radius:", ui_daemon:get_border_radius(), 100, true, function(value)
            ui_daemon:set_border_radius(value)
        end),
        separator(),
        slider("Animations FPS:", ui_daemon:get_animations_framerate(), 360, true, function(value)
            ui_daemon:set_animations_framerate(value)
        end, 1),
        checkbox_widget("animations", "Animations:"),
        separator(),
        checkbox_widget("show_lockscreen_on_login", "Lock on Login:"),
    }
end

function ui.mt:__call()
    return new()
end

return setmetatable(ui, ui.mt)