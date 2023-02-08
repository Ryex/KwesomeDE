-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------
local awful = require("awful")
local gobject = require("gears.object")
local gtable = require("gears.table")
local gtimer = require("gears.timer")
local ruled = require("ruled")
local wibox = require("wibox")
local widgets = require("ui.widgets")
local beautiful = require("beautiful")
local helpers = require("helpers")
local dpi = beautiful.xresources.apply_dpi
local capi = {
    awesome = awesome
}

local theme = {}
local instance = nil

local path = ...

local window = [[ lua -e "
    local lgi = require 'lgi'
    local Gtk = lgi.require('Gtk', '3.0')

    -- Create top level window with some properties and connect its 'destroy'
    -- signal to the event loop termination.
    local window = Gtk.Window {
    title = 'Theme Manager',
    default_width = 0,
    default_height = 0,
    on_destroy = Gtk.main_quit
    }

    if tonumber(Gtk._version) >= 3 then
    window.has_resize_grip = true
    end

    -- local icon = 'screen-recorder'
    -- pixbuf24 = Gtk.IconTheme.get_default():load_icon(icon, 24, 0)
    -- pixbuf32 = Gtk.IconTheme.get_default():load_icon(icon, 32, 0)
    -- pixbuf48 = Gtk.IconTheme.get_default():load_icon(icon, 48, 0)
    -- pixbuf64 = Gtk.IconTheme.get_default():load_icon(icon, 64, 0)
    -- pixbuf96 = Gtk.IconTheme.get_default():load_icon(icon, 96, 0)
    -- window:set_icon_list({pixbuf24, pixbuf32, pixbuf48, pixbuf64, pixbuf96});

    window:set_wmclass('awesome-app-theme-manager', 'awesome-app-theme-manager')

    -- Show window and start the loop.
    window:show_all()
    Gtk.main()
"
]]

function theme:show()
    helpers.client.run_or_raise_with_shell({
        class = "awesome-app-theme-manager"
    }, false, window)
end

function theme:hide()
    if self._private.client ~= nil then
        self._private.client:kill()
    end
    self._private.visible = false
    self:emit_signal("visible", false)
end

function theme:toggle()
    if self._private.visible == true then
        self:hide()
    else
        self:show()
    end
end

local function new()
    local ret = gobject {}
    gtable.crush(ret, theme, true)

    ret._private = {}

    local stack = wibox.layout.stack()
    stack:set_top_only(true)
    stack:add(require(path .. ".main")(ret, stack))
    stack:add(require(path .. ".settings")(stack))

    ruled.client.connect_signal("request::rules", function()
        ruled.client.append_rule {
            rule = {
                class = "awesome-app-theme-manager"
            },
            properties = {
                floating = true,
                width = dpi(800),
                height = 1,
                placement = awful.placement.centered
            },
            callback = function(c)
                ret._private.client = c

                c:connect_signal("unmanage", function()
                    ret._private.visible = false
                    ret._private.client = nil
                end)

                c.custom_titlebar = true
                c.can_resize = false
                c.can_tile = false

                -- Settings placement in properties doesn't work
                c.x = (c.screen.geometry.width / 2) - (dpi(800) / 2)
                c.y = (c.screen.geometry.height / 2) - (dpi(1060) / 2)

                local titlebar = widgets.titlebar(c, {
                    position = "top",
                    size = dpi(1060),
                    bg = beautiful.colors.background
                })
                titlebar:setup{
                    widget = wibox.widget {
                        widget = wibox.container.margin,
                        margins = dpi(15),
                        stack
                    }
                }

                capi.awesome.connect_signal("colorscheme::changed", function(old_colorscheme_to_new_map)
                    titlebar:set_bg(beautiful.colors.background)
                end)

                gtimer.delayed_call(function()
                    ret._private.visible = true
                    ret:emit_signal("visible", true)
                end)
            end
        }
    end)

    return ret
end

if not instance then
    instance = new()
end
return instance
