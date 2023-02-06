-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------
local awful = require("awful")
local wibox = require("wibox")
local beautiful = require("beautiful")
local twidget = require("ui.widgets.text")
local dpi = beautiful.xresources.apply_dpi
local setmetatable = setmetatable

local client_thumbnail = {
    mt = {}
}

local function get_client_thumbnail(client)
    -- Thumbnails for clients with custom titlebars, i.e welcome/screenshot/record/theme manager
    -- won't work correctly since all the UI is hacked on with the titlebars which aren't included
    -- when taking a screenshot with awful.screenshot
    if client:isvisible() and client.custom_titlebar ~= true then
        local screenshot = awful.screenshot {
            client = client
        }
        screenshot:refresh()
        client.thumbnail = screenshot.surface
    end

    if client.thumbnail == nil then
        return {
            font_icon = client.font_icon
        }
    else
        return {
            thumbnail = client.thumbnail
        }
    end
end

local function new(client)
    local thumbnail = get_client_thumbnail(client)
    local widget = thumbnail.thumbnail and wibox.widget {
        widget = wibox.widget.imagebox,
        horizontal_fit_policy = "fit",
        vertical_fit_policy = "fit",
        image = thumbnail.thumbnail
    } or wibox.widget {
        widget = twidget,
        forced_width = dpi(300),
        forced_height = dpi(300),
        halign = "center",
        valign = "center",
        size = (thumbnail.font_icon.size or 20) * 2,
        icon = thumbnail.font_icon
    }

    return widget
end

function client_thumbnail.mt:__call(...)
    return new(...)
end

return setmetatable(client_thumbnail, client_thumbnail.mt)
