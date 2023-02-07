-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------
local awful = require("awful")
local mwidget = require("ui.widgets.menu")
local favorites_daemon = require("daemons.system.favorites")
local setmetatable = setmetatable

local client_menu = {
    mt = {}
}

local function client_checkbox_button(client, property, text, on_press)
    local button = mwidget.checkbox_button {
        color = client.font_icon.color,
        text = text,
        on_press = function()
            client[property] = not client[property]
            if on_press ~= nil then
                on_press()
            end
        end
    }

    client:connect_signal("property::" .. property, function()
        if client[property] then
            button:turn_on()
        else
            button:turn_off()
        end
    end)

    return button
end

local function new(client)
    local maximize_menu = mwidget {client_checkbox_button(client, "maximized", "Maximize"),
                                   client_checkbox_button(client, "maximized_horizontal", "Maximize Horizontally"),
                                   client_checkbox_button(client, "maximized_vertical", "Maximize Vertically")}

    local layer_menu = mwidget {client_checkbox_button(client, "above", "Above"),
                                client_checkbox_button(client, "below", "Below"),
                                client_checkbox_button(client, "ontop", "On Top")}

    local pin_to_taskbar_button = mwidget.checkbox_button {
        color = client.font_icon.color,
        text = "Pin to Taskbar",
        on_press = function(self)
            if favorites_daemon:is_favorite(client) then
                self:turn_off()
                favorites_daemon:remove_favorite(client)
            else
                self:turn_on()
                favorites_daemon:add_favorite(client)
            end
        end
    }

    if favorites_daemon:is_favorite(client) then
        pin_to_taskbar_button:turn_on()
    else
        pin_to_taskbar_button:turn_off()
    end

    local menu = mwidget {
        mwidget.button {
            icon = client.font_icon,
            text = client.class,
            on_press = function()
                client:jump_to()
            end
        },
        pin_to_taskbar_button,
        mwidget.sub_menu_button {
            text = "Maximize",
            arrow_color = client.font_icon.color,
            sub_menu = maximize_menu
        },
        client_checkbox_button(client, "minimized", "Minimize"),
        client_checkbox_button(client, "fullscreen", "Fullscreen"),
        client_checkbox_button(client, "titlebar", "Titlebar", function()
            awful.titlebar.toggle(client)
        end),
        client_checkbox_button(client, "sticky", "Sticky"),
        client_checkbox_button(client, "hidden", "Hidden"),
        client_checkbox_button(client, "floating", "Floating"),
        mwidget.sub_menu_button {
            text = "Layer",
            arrow_color = client.font_icon.color,
            sub_menu = layer_menu
        },
        mwidget.button {
            text = "Close",
            on_press = function()
                client:kill()
            end
        }}

    -- At the time this funciton runs client.custom_titlebar is still nil
    -- so check if that property change and if so remove the titlebar toggle button
    client:connect_signal("property::custom_titlebar", function()
        if client.custom_titlebar == true then
            menu:remove(6)
        end
    end)

    return menu
end

function client_menu.mt:__call(...)
    return new(...)
end

return setmetatable(client_menu, client_menu.mt)