-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------
local awful = require("awful")
local gobject = require("gears.object")
local gtable = require("gears.table")
local gtimer = require("gears.timer")
local gstring = require("gears.string")
local gdebug = require("gears.debug")
local wibox = require("wibox")
local beautiful = require("beautiful")
local naughty = require("naughty")
local helpers = require("helpers")
local filesystem = require("external.filesystem")
local async = require("external.async")
local json = require("external.json")
local ipairs = ipairs
local table = table
local os = os

local notifications = {}
local instance = nil

local PATH = filesystem.filesystem.get_cache_dir("notifications")
local ICONS_PATH = PATH .. "icons/"
local DATA_PATH = PATH .. "data.json"

local function save_notification(self, notification)
    notification.time = os.date("%Y-%m-%dT%H:%M:%S")
    notification.uuid = helpers.string.random_uuid()

    local icon_path = ICONS_PATH .. notification.uuid .. ".svg"
    local app_icon_path = ICONS_PATH .. notification.uuid .. "_app.svg"

    table.insert(self._private.notifications, {
        uuid = notification.uuid,
        app_font_icon = notification.app_font_icon,
        app_icon = app_icon_path,
        app_name = notification.app_name,
        font_icon = notification.font_icon,
        icon = icon_path,
        title = gstring.xml_unescape(notification.title),
        message = gstring.xml_unescape(notification.message),
        time = notification.time
    })

    wibox.widget.draw_to_svg_file(wibox.widget {
        widget = wibox.widget.imagebox,
        forced_width = 35,
        forced_height = 35,
        image = notification.icon
    }, icon_path, 35, 35)

    wibox.widget.draw_to_svg_file(wibox.widget {
        widget = wibox.widget.imagebox,
        forced_width = 35,
        forced_height = 35,
        image = notification.app_icon
    }, app_icon_path, 35, 35)

    self._private.save_timer:again()
end

local function read_notifications(self)
    local file = filesystem.file.new_for_path(DATA_PATH)
    file:read(function(error, content)
        if error == nil then
            self._private.notifications = json.decode(content) or {}

            if #self._private.notifications > 0 then
                for _, notification in ipairs(self._private.notifications) do
                    local tasks = {}

                    if notification.font_icon == nil then
                        local icon = filesystem.file.new_for_path(notification.icon)
                        table.insert(tasks, async.callback(icon, icon.exists))
                    end
                    if notification.app_font_icon == nil then
                        local icon = filesystem.file.new_for_path(notification.app_icon)
                        table.insert(tasks, async.callback(icon, icon.exists))
                    end

                    async.all(tasks, function(error, results)
                        if results then
                            if error == nil then
                                if results[1] == nil or results[1][1] == false then
                                    notification.font_icon = beautiful.icons.message
                                end
                                if results[2] == nil or results[2][1] == false then
                                    notification.app_font_icon = beautiful.icons.window
                                end
                            else
                                notification.font_icon = beautiful.icons.message
                                notification.app_font_icon = beautiful.icons.window
                            end
                        end

                        self:emit_signal("new", notification)
                    end)
                end
            else
                self:emit_signal("empty")
            end
        else
            self:emit_signal("empty")
        end
    end)
end

function notifications:remove_all_notifications()
    self._private.notifications = {}
    self._private.save_timer:again()
    filesystem.filesystem.remove_directory(ICONS_PATH)
    self:emit_signal("empty")
end

function notifications:remove_notification(notification_data)
    local index = 0
    for i, notification in ipairs(self._private.notifications) do
        if notification.uuid == notification_data.uuid then
            index = i
            break
        end
    end

    if index ~= 0 then
        local file = filesystem.file.new_for_path(self._private.notifications[index].icon)
        file:delete()

        table.remove(self._private.notifications, index)
        self._private.save_timer:again()
        if #self._private.notifications == 0 then
            self:emit_signal("empty")
        end
    end
end

function notifications:is_suspended()
    return self.suspended
end

function notifications:set_dont_disturb(value)
    if self.suspended ~= value then
        self.suspended = value
        helpers.settings["notifications.dont_disturb"] = value
        self:emit_signal("state", value)
    end
end

function notifications:block_on_locked()
    if self.suspended == false then
        self.suspended = true
        self.was_not_suspended = true
    end
end

function notifications:unblock_on_unlocked()
    if self.was_not_suspended == true then
        self.suspended = false
        self.was_not_suspended = nil
    end
end

function notifications:toggle()
    if self.suspended == true then
        self:set_dont_disturb(false)
    else
        self:set_dont_disturb(true)
    end
end

local function new()
    local ret = gobject {}
    gtable.crush(ret, notifications, true)

    ret._private = {}
    ret._private.notifications = {}

    local file = filesystem.file.new_for_path(DATA_PATH)
    ret._private.save_timer = gtimer {
        timeout = 1,
        autostart = false,
        single_shot = true,
        callback = function()
            local _notifications_status, notifications = pcall(function()
                return json.encode(ret._private.notifications)
            end)
            if not _notifications_status or not notifications then
                gdebug.print_warning(
                    "Failed to encode notifications! " ..
                    "Notifications will not be saved. "
                )
            else
                file:write(notifications)
            end
        end
    }

    filesystem.filesystem.make_directory(ICONS_PATH)

    gtimer.delayed_call(function()
        ret:set_dont_disturb(helpers.settings["notifications.dont_disturb"])
        read_notifications(ret)
    end)

    naughty.connect_signal("request::display", function(notification)
        save_notification(ret, notification)
        ret:emit_signal("new", notification)
    end)

    return ret
end

if not instance then
    instance = new()
end
return instance
