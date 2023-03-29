-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------
local gshape = require("gears.shape")
local wibox = require("wibox")
local widgets = require("ui.widgets")
local app = require("ui.apps.app")
local beautiful = require("beautiful")
local screenshot_daemon = require("daemons.system.screenshot")
local helpers = require("helpers")
local dpi = beautiful.xresources.apply_dpi

local instance = nil

local function separator()
    return wibox.widget {
        widget = widgets.background,
        forced_height = dpi(2),
        shape = helpers.ui.rrect(),
        bg = beautiful.colors.surface,
    }
end

local function setting_container(widget)
    return wibox.widget {
        widget = wibox.container.margin,
        margins = dpi(15),
        widget
    }
end

local function button(icon, text, on_release, on_by_default)
    local icon = wibox.widget {
        widget = widgets.text,
        halign = "center",
        color = beautiful.icons.camera_retro.color,
        text_normal_bg = beautiful.icons.camera_retro.color,
        text_on_normal_bg = beautiful.colors.transparent,
        icon = icon
    }

    local text = wibox.widget {
        widget = widgets.text,
        halign = "center",
        size = 12,
        color = beautiful.colors.on_surface,
        text_normal_bg = beautiful.colors.on_surface,
        text_on_normal_bg = beautiful.colors.transparent,
        text = text
    }

    return wibox.widget {
        widget = widgets.button.elevated.state,
        on_by_default = on_by_default,
        forced_width = dpi(120),
        forced_height = dpi(120),
        normal_bg = beautiful.colors.surface,
        on_normal_bg = beautiful.icons.camera_retro.color,
        on_release = function(self)
            on_release(self)
        end,
        {
            layout = wibox.layout.fixed.vertical,
            spacing = dpi(15),
            icon,
            text
        }
    }
end

local function show_cursor()
    local checkbox = wibox.widget {
        widget = widgets.checkbox,
        state = screenshot_daemon:get_show_cursor(),
        handle_active_color = beautiful.icons.camera_retro.color,
        on_turn_on = function()
            screenshot_daemon:set_show_cursor(true)
        end,
        on_turn_off = function()
            screenshot_daemon:set_show_cursor(false)
        end
    }

    local text = wibox.widget {
        widget = widgets.text,
        valign = "center",
        size = 15,
        text = "Show Cursor:"
    }

    return wibox.widget {
        layout = wibox.layout.fixed.horizontal,
        forced_height = dpi(35),
        spacing = dpi(5),
        text,
        checkbox
    }
end

local function delay()
    local title = wibox.widget {
        widget = widgets.text,
        size = 15,
        text = "Delay:"
    }

    local slider = widgets.slider_text_input {
        slider_width = dpi(150),
        text_input_width = dpi(60),
        value = screenshot_daemon:get_delay(),
        round = true,
        maximum = 100,
        bar_active_color = beautiful.icons.camera_retro.color,
        selection_bg = beautiful.icons.camera_retro.color,
    }

    slider:connect_signal("property::value", function(self, value, instant)
        screenshot_daemon:set_delay(value)
    end)

    return wibox.widget {
        layout = wibox.layout.fixed.horizontal,
        forced_height = dpi(35),
        spacing = dpi(15),
        title,
        slider
    }
end

local function folder_picker()
    local title = wibox.widget {
        widget = widgets.text,
        size = 15,
        text = "Folder:"
    }

    local file_picker = wibox.widget {
        widget = widgets.picker,
        text_input_forced_width = dpi(340),
        type = "file",
        initial_value = screenshot_daemon:get_folder(),
        on_changed = function(text)
            screenshot_daemon:set_folder(text)
        end
    }

    return wibox.widget {
        layout = wibox.layout.fixed.horizontal,
        forced_height = dpi(35),
        spacing = dpi(15),
        title,
        file_picker
    }
end

local function main()
    local selection_button = nil
    local screen_button = nil
    local window_button = nil
    local color_picker_button = nil

    selection_button = button(beautiful.icons.scissors, "Selection", function()
        screenshot_daemon:set_screenshot_method("selection")
        selection_button:turn_on()
        screen_button:turn_off()
        window_button:turn_off()
        color_picker_button:turn_off()
    end, true)

    screen_button = button(beautiful.icons.computer, "Screen", function()
        screenshot_daemon:set_screenshot_method("screen")
        selection_button:turn_off()
        screen_button:turn_on()
        window_button:turn_off()
        color_picker_button:turn_off()
    end)

    window_button = button(beautiful.icons.window, "Window", function()
        screenshot_daemon:set_screenshot_method("window")
        selection_button:turn_off()
        screen_button:turn_off()
        window_button:turn_on()
        color_picker_button:turn_off()
    end)

    color_picker_button = button(beautiful.icons.palette, "Pick Color", function()
        screenshot_daemon:set_screenshot_method("color_picker")
        selection_button:turn_off()
        screen_button:turn_off()
        window_button:turn_off()
        color_picker_button:turn_on()
    end)

    local screenshot_button = wibox.widget {
        widget = widgets.button.text.normal,
        size = 15,
        normal_bg = beautiful.icons.camera_retro.color,
        text_normal_bg = beautiful.colors.on_accent,
        text = "Screenshot",
        on_release = function()
            screenshot_daemon:screenshot()
        end
    }

    return wibox.widget {
        layout = wibox.layout.fixed.vertical,
        spacing = dpi(15),
        {
            widget = wibox.layout.fixed.horizontal,
            spacing = dpi(15),
            selection_button,
            screen_button,
            window_button,
            color_picker_button
        },
        {
            widget = widgets.background,
            shape = helpers.ui.rrect(),
            bg = beautiful.colors.background,
            border_width = dpi(2),
            border_color = beautiful.colors.surface,
            {
                layout = wibox.layout.fixed.vertical,
                setting_container(delay()),
                separator(),
                setting_container(show_cursor()),
                separator(),
                setting_container(folder_picker())
            }
        },
        screenshot_button
    }
end

local function new()
    local app = app {
        title ="Screenshot",
        class = "Screenshot",
        width = dpi(560),
        height = dpi(455),
        show_titlebar = true,
        widget_fn = function()
            return main()
        end
    }

    screenshot_daemon:connect_signal("started", function()
        app:set_hidden(true)
    end)

    screenshot_daemon:connect_signal("ended", function()
        app:set_hidden(false)
    end)

    screenshot_daemon:connect_signal("error::create_file", function()
        app:set_hidden(false)
    end)

    screenshot_daemon:connect_signal("error::create_directory", function()
        app:set_hidden(false)
    end)

    return app
end

if not instance then
    instance = new()
end
return instance
