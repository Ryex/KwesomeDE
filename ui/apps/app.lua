-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------
local awful = require("awful")
local gobject = require("gears.object")
local gtable = require("gears.table")
local gshape = require("gears.shape")
local ruled = require("ruled")
local wibox = require("wibox")
local widgets = require("ui.widgets")
local beautiful = require("beautiful")
local helpers = require("helpers")
local dpi = beautiful.xresources.apply_dpi
local capi = {
    awesome = awesome,
    client = client
}

local app = {
    mt = {}
}

local function titlebar(app)
    local minimize = wibox.widget {
        widget = widgets.button.elevated.state,
        forced_width = dpi(20),
        forced_height = dpi(20),
        on_by_default = capi.client.focus == app:get_client(),
        normal_shape = gshape.isosceles_triangle,
        normal_bg = beautiful.colors.surface,
        on_normal_bg = app:get_client().font_icon.color,
        on_release = function(self)
            app:get_client().minimized = not app:get_client().minimized
        end
    }

    local close = wibox.widget {
        widget = widgets.button.elevated.state,
        forced_width = dpi(20),
        forced_height = dpi(20),
        on_by_default = capi.client.focus == app:get_client(),
        normal_shape = gshape.circle,
        normal_bg = beautiful.colors.surface,
        on_normal_bg = app:get_client().font_icon.color,
        on_release = function()
            app:get_client():kill()
        end
    }

    local font_icon = wibox.widget {
        widget = widgets.button.text.state,
        halign = "center",
        disabled = true,
        paddings = 0,
        on_by_default = capi.client.focus == app:get_client(),
        icon = app:get_client().font_icon,
        scale = 0.7,
        normal_bg = beautiful.colors.background,
        on_normal_bg = beautiful.colors.background,
        text_normal_bg = beautiful.colors.on_background,
        text_on_normal_bg = app:get_client().font_icon.color,
    }

    local title = wibox.widget {
        widget = widgets.text,
        halign = "center",
        size = 12,
        text = app:get_client().name,
        color = beautiful.colors.on_background,
    }

    app:get_client():connect_signal("focus", function()
        font_icon:turn_on()
        minimize:turn_on()
        close:turn_on()
    end)

    app:get_client():connect_signal("unfocus", function()
        font_icon:turn_off()
        minimize:turn_off()
        close:turn_off()
    end)

    return wibox.widget {
        widget = wibox.container.margin,
        margins = { left = dpi(15) },
        {
            layout = wibox.layout.align.horizontal,
            forced_height = dpi(35),
            {
                widget = wibox.container.place,
                halign = "center",
                {
                    layout = wibox.layout.fixed.horizontal,
                    spacing = dpi(15),
                    font_icon,
                    title
                }
            },
            {
                widget = wibox.container.place,
                halign = "right",
                {
                    layout = wibox.layout.fixed.horizontal,
                    spacing = dpi(15),
                    minimize,
                    {
                        widget = wibox.container.margin,
                        margins = { right = dpi(15) },
                        close
                    }
                }
            }
        }
    }
end

function app:show()
    helpers.client.run_or_raise({
        class = self._private.class
    }, true, self._private.command, {shell = true})
end

function app:hide()
    if self._private.client ~= nil then
        self._private.client:kill()
    end
    self._private.visible = false
end

function app:toggle()
    if self._private.visible == true then
        self:hide()
    else
        self:show()
    end
end

function app:get_client()
    return self._private.client
end

function app:set_hidden(hidden)
    local client = self:get_client()
    if client then
        client.hidden = hidden
    end
end

function app:set_width(width)
    self._private.width = width
end

function app:set_height(height)
    self._private.height = height
end

local function new(args)
    local ret = gobject {}
    gtable.crush(ret, app, true)

    ret._private = {}

    ret._private.title =args.title or ""
    ret._private.class = args.class or ""
    ret._private.width = args.width or nil
    ret._private.height = args.height or nil
    ret._private.widget_fn = args.widget_fn or nil
    ret._private.show_titlebar = args.show_titlebar or nil
    ret._private.command = string.format([[ lua -e "
    local lgi = require 'lgi'
    local Gtk = lgi.require('Gtk', '3.0')

    -- Create top level window with some properties and connect its 'destroy'
    -- signal to the event loop termination.
    local window = Gtk.Window {
    title = '%s',
    default_width = 0,
    default_height = 0,
    on_destroy = Gtk.main_quit
    }

    if tonumber(Gtk._version) >= 3 then
    window.has_resize_grip = true
    end

    window:set_wmclass('%s', '%s')

    -- Show window and start the loop.
    window:show_all()
    Gtk.main()
"
]], ret._private.title, ret._private.class, ret._private.class)

    ret._private.first = true

    ruled.client.connect_signal("request::rules", function()
        ruled.client.append_rule {
            rule = {
                class = ret._private.class
            },
            properties = {
                floating = true,
                height = 1,
                placement = awful.placement.centered
            },
            callback = function(c)
                ret._private.client = c
                ret:emit_signal("init")

                c:connect_signal("unmanage", function()
                    ret._private.visible = false
                    ret._private.client = nil
                end)

                c.width = ret._private.width

                c.custom_titlebar = true
                c.can_resize = false
                c.can_tile = false

                -- Settings placement in properties doesn't work
                c.x = (c.screen.geometry.width / 2) - (ret._private.width / 2)
                c.y = (c.screen.geometry.height / 2) - (ret._private.height / 2)

                ret._private.titlebar = widgets.titlebar(c, {
                    position = "top",
                    size = ret._private.height,
                    bg = beautiful.colors.background
                })

                capi.awesome.connect_signal("colorscheme::changed", function(old_colorscheme_to_new_map)
                    ret._private.titlebar:set_bg(beautiful.colors.background)
                end)

                c:connect_signal("request::unmanage", function()
                    ret:emit_signal("visibility", false)
                end)

                c:connect_signal("managed", function()
                    if ret._private.first then
                        ret._private.widget = wibox.widget {
                            widget = wibox.container.margin,
                            margins = { top = dpi(10), bottom = dpi(15), left = dpi(15), right = dpi(15) },
                            ret._private.widget_fn()
                        }

                        if ret._private.show_titlebar then
                            ret._private.widget = wibox.widget {
                                layout = wibox.layout.align.vertical,
                                titlebar(ret),
                                ret._private.widget
                            }
                        end

                        ret._private.first = false
                    end

                    ret._private.titlebar:setup{
                        widget = ret._private.widget
                    }
                end)

                ret._private.visible = true
                ret:emit_signal("visibility", true)
            end
        }
    end)

    return ret
end

function app.mt:__call(...)
    return new(...)
end

return setmetatable(app, app.mt)