-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------
local awful = require("awful")
local ruled = require("ruled")
local wibox = require("wibox")
local widgets = require("ui.widgets")
local beautiful = require("beautiful")
local naughty = require("naughty")
local notifications_daemon = require("daemons.system.notifications")
local helpers = require("helpers")
local dpi = beautiful.xresources.apply_dpi
local ipairs = ipairs
local type = type

-- naughty.expiration_paused = true
-- naughty.image_animations_enabled = true
naughty.persistence_enabled = true

local function get_oldest_notification()
    for _, notification in ipairs(naughty.active) do
        if notification and notification.timeout > 0 then
            return notification
        end
    end

    -- Fallback to first one.
    return naughty.active[1]
end

local function play_sound(n)
    if n.category == "device.added" or n.category == "network.connected" then
        awful.spawn("canberra-gtk-play -i service-login", false)
    elseif n.category == "device.removed" or n.category == "network.disconnected" then
        awful.spawn("canberra-gtk-play -i service-logout", false)
    elseif n.category == "device.error" or n.category == "im.error" or n.category == "network.error" or n.category ==
        "transfer.error" then
        awful.spawn("canberra-gtk-play -i dialog-warning", false)
    elseif n.category == "email.arrived" then
        awful.spawn("canberra-gtk-play -i message", false)
    else
        awful.spawn("canberra-gtk-play -i bell", false)
    end
end

ruled.notification.connect_signal("request::rules", function()
    ruled.notification.append_rule {
        rule = {},
        properties = {
            screen = awful.screen.preferred,
            position = "top_right",
            implicit_timeout = 5,
            resident = true
        }
    }
    ruled.notification.append_rule {
        rule = {
            app_name = "networkmanager-dmenu"
        },
        properties = {
            icon = helpers.icon_theme:get_icon_path("networkmanager")
        }
    }
    ruled.notification.append_rule {
        rule = {
            app_name = "blueman"
        },
        properties = {
            icon = helpers.icon_theme:get_icon_path("blueman-device")
        }
    }
end)

naughty.connect_signal("request::action_icon", function(a, context, hints)
    a.icon = helpers.icon_theme:get_icon_path(hints.id)
end)

naughty.connect_signal("added", function(n)
    if n.title == "" or n.title == nil then
        n.title = n.app_name
    end

    if n._private.app_font_icon == nil then
        n.app_font_icon = beautiful.get_font_icon_for_app_name(n.app_name)
        if n.app_font_icon == nil then
            n.app_font_icon = beautiful.icons.window
        end
    else
        n.app_font_icon = n._private.app_font_icon
    end
    n.font_icon = n._private.font_icon

    if type(n._private.app_icon) == "table" then
        n.app_icon = helpers.icon_theme:choose_icon(n._private.app_icon)
    else
        n.app_icon = helpers.icon_theme:get_icon_path(n._private.app_icon or n.app_name)
    end

    if type(n.icon) == "table" then
        n.icon = helpers.icon_theme:choose_icon(n.icon)
    end

    if n.app_icon == "" or n.app_icon == nil then
        n.app_icon = helpers.icon_theme:get_icon_path("application-default-icon")
    end

    if (n.icon == "" or n.icon == nil) and n.font_icon == nil then
        n.font_icon = beautiful.icons.message
        n.icon = helpers.icon_theme:get_icon_path("preferences-desktop-notification-bell")
    end
end)

naughty.connect_signal("request::display", function(n)
    local accent_color = n.app_font_icon.color or n.font_icon.color or beautiful.colors.random_accent_color()

    if notifications_daemon:is_suspended() == true and n.ignore_suspend ~= true then
        return
    end

    local app_icon = nil
    if n.app_font_icon == nil then
        app_icon = wibox.widget {
            widget = wibox.container.constraint,
            strategy = "max",
            height = dpi(20),
            width = dpi(20),
            {
                widget = wibox.widget.imagebox,
                halign = "center",
                valign = "center",
                clip_shape = helpers.ui.rrect(beautiful.border_radius),
                image = n.app_icon
            }
        }
    else
        app_icon = wibox.widget {
            widget = widgets.text,
            icon = n.app_font_icon,
            size = n.app_font_icon.size
        }
    end

    local app_name = wibox.widget {
        widget = widgets.text,
        size = 12,
        text = n.app_name:gsub("^%l", string.upper)
    }

    local dismiss = wibox.widget {
        widget = widgets.button.text.normal,
        icon = beautiful.icons.xmark,
        text_normal_bg = beautiful.colors.on_background,
        size = 12,
        on_release = function()
            n:destroy(naughty.notification_closed_reason.dismissed_by_user)
        end
    }

    local timeout_arc = wibox.widget {
        widget = wibox.container.arcchart,
        forced_width = dpi(45),
        forced_height = dpi(45),
        max_value = 100,
        min_value = 0,
        value = 0,
        thickness = dpi(6),
        rounded_edge = true,
        bg = beautiful.colors.surface,
        colors = {
            accent_color
        },
        dismiss
    }

    local icon = nil
    if n.font_icon == nil then
        icon = wibox.widget {
            widget = wibox.container.constraint,
            strategy = "max",
            height = dpi(40),
            width = dpi(40),
            {
                widget = wibox.widget.imagebox,
                clip_shape = helpers.ui.rrect(beautiful.border_radius),
                image = n.icon
            }
        }
    else
        icon = wibox.widget {
            widget = widgets.text,
            size = 30,
            icon = n.font_icon
        }
    end

    local title = wibox.widget {
        widget = wibox.container.scroll.horizontal,
        step_function = wibox.container.scroll.step_functions.waiting_nonlinear_back_and_forth,
        speed = 50,
        {
            widget = widgets.text,
            size = 15,
            bold = true,
            text = n.title
        }
    }

    local color = accent_color
    if n.urgency == "critical" then
        color = beautiful.colors.bright_red
    end

    local urgency_color = wibox.widget {
        widget = wibox.container.background,
        forced_height = dpi(10),
        shape = helpers.ui.rrect(beautiful.border_radius),
        bg = color
    }

    local message = wibox.widget {
        widget = wibox.container.constraint,
        strategy = "max",
        height = dpi(60),
        {
            layout = widgets.overflow.vertical,
            scrollbar_widget = {
                widget = wibox.widget.separator,
                shape = helpers.ui.rrect(beautiful.border_radius)
            },
            scrollbar_width = dpi(10),
            scroll_speed = 3,
            {
                widget = widgets.text,
                size = 15,
                text = n.message
            }
        }
    }

    local actions = wibox.widget {
        layout = wibox.layout.flex.horizontal,
        spacing = dpi(15)
    }

    for _, action in ipairs(n.actions) do
        local button = wibox.widget {
            widget = widgets.button.text.normal,
            size = 12,
            normal_bg = beautiful.colors.surface,
            text_normal_bg = beautiful.colors.on_surface,
            text = action.name,
            on_press = function()
                action:invoke()
            end
        }
        actions:add(button)
    end

    local widget = naughty.layout.box {
        notification = n,
        type = "notification",
        cursor = beautiful.hover_cursor,
        minimum_width = dpi(400),
        minimum_height = dpi(50),
        maximum_width = dpi(400),
        maximum_height = dpi(300),
        shape = helpers.ui.rrect(beautiful.border_radius),
        bg = beautiful.colors.background,
        border_width = 0,
        widget_template = {
            widget = wibox.container.background,
            {
                widget = wibox.container.margin,
                margins = dpi(25),
                {
                    layout = wibox.layout.fixed.vertical,
                    spacing = dpi(15),
                    {
                        layout = wibox.layout.align.horizontal,
                        {
                            layout = wibox.layout.fixed.horizontal,
                            spacing = dpi(15),
                            app_icon,
                            app_name
                        },
                        nil,
                        timeout_arc
                    },
                    {
                        layout = wibox.layout.fixed.horizontal,
                        spacing = dpi(15),
                        icon,
                        title
                    },
                    urgency_color,
                    message,
                    actions
                }
            }
        }
    }

    -- Don't destroy the notification on click
    widget.buttons = {}

    local anim = helpers.animation:new{
        duration = n.timeout,
        target = 100,
        easing = helpers.animation.easing.linear,
        reset_on_stop = false,
        update = function(self, pos)
            timeout_arc.value = pos
        end
    }

    anim:connect_signal("ended", function()
        n:destroy()
    end)

    widget:connect_signal("mouse::enter", function()
        -- Absurdly big number because setting it to 0 doesn't work
        n:set_timeout(4294967)
        anim:stop()
    end)

    widget:connect_signal("mouse::leave", function()
        anim:start()
    end)

    local notification_height = widget.height + beautiful.notification_spacing
    local total_notifications_height = (#naughty.active) * notification_height

    if total_notifications_height > n.screen.workarea.height then
        get_oldest_notification():destroy(naughty.notification_closed_reason.too_many_on_screen)
    end

    anim:start()

    play_sound(n)
end)

require(... .. ".bluetooth")
require(... .. ".email")
require(... .. ".error")
require(... .. ".github")
require(... .. ".gitlab")
require(... .. ".lock")
require(... .. ".network")
require(... .. ".picom")
require(... .. ".playerctl")
require(... .. ".record")
require(... .. ".screenshot")
require(... .. ".theme")
require(... .. ".udev")
require(... .. ".upower")
