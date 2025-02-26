-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------
local wibox = require("wibox")
local widgets = require("ui.widgets")
local beautiful = require("beautiful")
local network_daemon = require("daemons.hardware.network")
local helpers = require("helpers")
local dpi = beautiful.xresources.apply_dpi
local setmetatable = setmetatable
local table = table
local pairs = pairs
local capi = {
    awesome = awesome
}

local wifi = {
    mt = {}
}

local function access_point_widget(layout, access_point)
    local widget = nil
    local anim = nil

    local wifi_icon = wibox.widget {
        widget = widgets.text,
        halign = "left",
        icon = access_point.strength > 66 and beautiful.icons.network.wifi_high or access_point.strength > 33 and
            beautiful.icons.network.wifi_medium or beautiful.icons.network.wifi_low,
        size = 25
    }

    local lock_icon = wibox.widget {
        widget = widgets.text,
        icon = beautiful.icons.lock,
        color = beautiful.icons.network.wifi_off.color,
        size = 20
    }

    local text_input = wibox.widget {
        widget = widgets.text_input,
        forced_width = dpi(440),
        obscure = true,
        initial = access_point.password,
        selection_bg = beautiful.icons.network.wifi_off.color,
        widget_template = wibox.widget {
            widget = widgets.background,
            shape = helpers.ui.rrect(),
            bg = beautiful.colors.surface,
            {
                widget = wibox.container.margin,
                margins = dpi(15),
                {
                    layout = wibox.layout.fixed.horizontal,
                    spacing = dpi(15),
                    {
                        widget = widgets.text,
                        icon = beautiful.icons.lock,
                        color = beautiful.icons.network.wifi_low.color
                    },
                    {
                        layout = wibox.layout.stack,
                        {
                            widget = wibox.widget.textbox,
                            id = "placeholder_role",
                            text = "Search:"
                        },
                        {
                            widget = wibox.widget.textbox,
                            id = "text_role"
                        },
                    }
                }
            }
        }
    }

    local toggle_password_obscure_button = wibox.widget {
        widget = widgets.checkbox,
        state = true,
        handle_active_color = beautiful.icons.network.wifi_off.color,
        on_turn_on = function()
            text_input:set_obscure(true)
        end,
        on_turn_off = function()
            text_input:set_obscure(false)
        end
    }

    local name = wibox.widget {
        widget = widgets.text,
        forced_width = dpi(600),
        forced_height = dpi(30),
        halign = "left",
        size = 12,
        text = access_point:is_active() and access_point.ssid .. " - Activated" or
            access_point.ssid,
        color = beautiful.colors.on_surface
    }

    local auto_connect_checkbox = wibox.widget {
        widget = widgets.checkbox,
        state = true,
        handle_active_color = beautiful.icons.network.wifi_off.color
    }

    local auto_connect_text = wibox.widget {
        widget = widgets.text,
        valign = "center",
        size = 12,
        color = beautiful.colors.on_surface,
        text = "Auto Connect:"
    }

    local cancel = wibox.widget {
        widget = widgets.button.text.normal,
        normal_bg = beautiful.colors.surface,
        text_normal_bg = beautiful.colors.on_surface,
        size = 12,
        text = "Cancel",
        on_release = function()
            text_input:unfocus()
            anim:set(dpi(65))
        end
    }

    local connect_or_disconnect = wibox.widget {
        widget = widgets.button.text.normal,
        normal_bg = beautiful.colors.surface,
        text_normal_bg = beautiful.colors.on_surface,
        size = 12,
        text = access_point:is_active() == true and "Disconnect" or "Connect",
        on_release = function()
            access_point:toggle(text_input:get_text(), auto_connect_checkbox:get_state())
        end
    }

    local spinning_circle = widgets.spinning_circle {
        forced_width = dpi(25),
        forced_height = dpi(25),
        thickness = dpi(10),
        run_by_default = false
    }

    local connect_or_disconnect_stack = wibox.widget {
        widget = wibox.layout.stack,
        top_only = true,
        connect_or_disconnect,
        spinning_circle
    }

    network_daemon:dynamic_connect_signal(access_point.hw_address .. "::state", function(self, new_state, old_state)
        name:set_text(access_point.ssid .. " - " .. network_daemon.device_state_to_string(new_state))

        if new_state ~= network_daemon.DeviceState.ACTIVATED then
            connect_or_disconnect:set_text("Connect")
        end

        if new_state == network_daemon.DeviceState.PREPARE then
            spinning_circle:start()
            connect_or_disconnect_stack:raise_widget(spinning_circle)
        elseif new_state == network_daemon.DeviceState.ACTIVATED then
            layout:remove_widgets(widget)
            layout:insert(1, widget)
            connect_or_disconnect:set_text("Disconnect")

            spinning_circle:stop()
            connect_or_disconnect_stack:raise_widget(connect_or_disconnect)

            text_input:unfocus()
            anim:set(dpi(65))
        end
    end)

    network_daemon:dynamic_connect_signal("access_point::connected", function(self, ssid, strength)
        spinning_circle:stop()
        connect_or_disconnect_stack:raise_widget(connect_or_disconnect)
    end)

    widget = wibox.widget {
        widget = wibox.container.constraint,
        mode = "exact",
        height = dpi(65),
        {
            widget = widgets.button.elevated.normal,
            id = "button",
            on_release = function(self)
                capi.awesome.emit_signal("access_point_widget::expanded", widget)
                text_input:focus()
                anim:set(dpi(250))
            end,
            {
                layout = wibox.layout.fixed.vertical,
                spacing = dpi(15),
                {
                    layout = wibox.layout.fixed.horizontal,
                    spacing = dpi(15),
                    wifi_icon,
                    name,
                    lock_icon
                },
                {
                    layout = wibox.layout.fixed.horizontal,
                    spacing = dpi(15),
                    text_input,
                    toggle_password_obscure_button
                },
                {
                    layout = wibox.layout.fixed.horizontal,
                    spacing = dpi(5),
                    auto_connect_text,
                    auto_connect_checkbox
                },
                {
                    layout = wibox.layout.flex.horizontal,
                    spacing = dpi(15),
                    connect_or_disconnect_stack,
                    cancel
                }
            }
        }
    }

    anim = helpers.animation:new{
        pos = dpi(65),
        duration = 0.2,
        easing = helpers.animation.easing.linear,
        update = function(self, pos)
            widget.height = pos
        end
    }

    capi.awesome.connect_signal("access_point_widget::expanded", function(toggled_on_widget)
        if toggled_on_widget ~= widget then
            text_input:unfocus()
            anim:set(dpi(65))
        end
    end)

    return widget
end

local function new()
    local hw_addresses = {}

    local function add_access_points(access_points, stack, layout)
        layout:reset()

        for _, hw_address in pairs(hw_addresses) do
            network_daemon:dynamic_disconnect_signals(hw_address .. "::state")
        end
        hw_addresses = {}
        network_daemon:dynamic_disconnect_signals("access_point::connected")

        for _, access_point in pairs(access_points) do
            table.insert(hw_addresses, access_point.hw_address)

            if access_point:is_active() then
                layout:insert(1, access_point_widget(layout, access_point))
            else
                layout:add(access_point_widget(layout, access_point))
            end
        end
        stack:raise_widget(layout)
    end

    local header = wibox.widget {
        widget = widgets.text,
        halign = "left",
        bold = true,
        color = beautiful.icons.network.wifi_off.color,
        text = "Wi-Fi"
    }

    local rescan = wibox.widget {
        widget = widgets.button.text.normal,
        forced_width = dpi(50),
        forced_height = dpi(50),
        text_normal_bg = beautiful.colors.on_background,
        icon = beautiful.icons.arrow_rotate_right,
        size = 15,
        on_release = function()
            network_daemon:scan_access_points()
        end
    }

    local settings = wibox.widget {
        widget = widgets.button.text.normal,
        forced_width = dpi(50),
        forced_height = dpi(50),
        text_normal_bg = beautiful.colors.on_background,
        icon = beautiful.icons.gear,
        size = 15,
        on_release = function()
            network_daemon:open_settings()
        end
    }

    local layout = wibox.widget {
        layout = wibox.layout.overflow.vertical,
        spacing = dpi(15),
        scrollbar_widget = widgets.scrollbar,
        scrollbar_width = dpi(10),
        step = 50
    }

    local no_wifi = wibox.widget {
        widget = widgets.text,
        halign = "center",
        icon = beautiful.icons.network.wifi_off,
        size = 100
    }

    local stack = wibox.widget {
        layout = wibox.layout.stack,
        top_only = true,
        layout,
        no_wifi
    }

    local seperator = wibox.widget {
        widget = widgets.background,
        forced_height = dpi(1),
        shape = helpers.ui.rrect(),
        bg = beautiful.colors.surface
    }

    network_daemon:connect_signal("wireless_state", function(self, state)
        if state == false then
            stack:raise_widget(no_wifi)
        end
    end)

    network_daemon:connect_signal("scan_access_points::success", function(self, access_points)
        add_access_points(access_points, stack, layout)
    end)

    add_access_points(network_daemon:get_access_points(), stack, layout)

    return wibox.widget {
        widget = wibox.container.margin,
        margins = dpi(25),
        {
            layout = wibox.layout.fixed.vertical,
            spacing = dpi(15),
            {
                layout = wibox.layout.align.horizontal,
                header,
                nil,
                {
                    layout = wibox.layout.fixed.horizontal,
                    spacing = dpi(15),
                    rescan,
                    settings
                }
            },
            seperator,
            stack
        }
    }
end

function wifi.mt:__call()
    return new()
end

return setmetatable(wifi, wifi.mt)