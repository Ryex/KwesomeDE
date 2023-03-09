local awful = require("awful")
local widgets = require("ui.widgets")
local welcome_app = require("ui.apps.welcome")
local theme_app = require("ui.apps.theme")
local action_panel = require(... .. ".panels.action")
local info_panel = require(... .. ".panels.info")
local notification_panel = require(... .. ".panels.notification")
local power_popup = require(... .. ".popups.power")
local lock_popup = require(... .. ".popups.lock")
local cpu_popup = require(... .. ".panels.action.info.cpu")
local ram_popup = require(... .. ".panels.action.info.ram")
local disk_popup = require(... .. ".panels.action.info.disk")
local audio_popup = require(... .. ".panels.action.info.audio")
local wifi_popup = require(... .. ".panels.action.dashboard.wifi")
local bluetooth_popup = require(... .. ".panels.action.dashboard.bluetooth")
local system_daemon = require("daemons.system.system")
local theme_daemon = require("daemons.system.theme")
local helpers = require("helpers")
local capi = {
    screen = screen,
    client = client
}

require(... .. ".desktop")
require(... .. ".popups.brightness")
require(... .. ".popups.keyboard_layout")
require(... .. ".popups.volume")
require(... .. ".notifications")
require(... .. ".titlebar")
require(... .. ".wibar")

capi.client.connect_signal("scanned", function()
    if system_daemon:is_new_version() or system_daemon:does_need_setup() then
        welcome_app:toggle()

        welcome_app:connect_signal("visibility", function(self, visible)
            if visible == false then
                theme_app:toggle()
            end
        end)
    end
end)

capi.client.connect_signal("property::fullscreen", function(c)
    if c.fullscreen then
        action_panel:hide()
        info_panel:hide()
        notification_panel:hide()
        cpu_popup:hide()
        ram_popup:hide()
        disk_popup:hide()
        audio_popup:hide()
        wifi_popup:hide()
        bluetooth_popup:hide()

        for screen in capi.screen do
            screen.left_wibar.ontop = false
            screen.top_wibar.ontop = false
        end
    else
        if #helpers.client.find({fullscreen = true}) == 0 then
            for screen in capi.screen do
                screen.left_wibar.ontop = true
                screen.top_wibar.ontop = true
            end
        end
    end
end)

capi.client.connect_signal("focus", function(c)
    if c.fullscreen then
        action_panel:hide()
        info_panel:hide()
        notification_panel:hide()
        cpu_popup:hide()
        ram_popup:hide()
        disk_popup:hide()
        audio_popup:hide()
        wifi_popup:hide()
        bluetooth_popup:hide()
    end
end)

action_panel:connect_signal("visibility", function(self, visible)
    if visible == true then
        power_popup:hide()
        notification_panel:hide()
    else
        cpu_popup:hide()
        ram_popup:hide()
        disk_popup:hide()
        audio_popup:hide()
        wifi_popup:hide()
        bluetooth_popup:hide()
    end
end)

info_panel:connect_signal("visibility", function(self, visible)
    if visible == true then
        power_popup:hide()
    end
end)

notification_panel:connect_signal("visibility", function(self, visible)
    if visible == true then
        action_panel:hide()
        power_popup:hide()
    end
end)

power_popup:connect_signal("visibility", function(self, visible)
    if visible == true then
        action_panel:hide()
        info_panel:hide()
        notification_panel:hide()
    end
end)

cpu_popup:connect_signal("visibility", function(self, visible)
    if visible == true then
        ram_popup:hide()
        disk_popup:hide()
        audio_popup:hide()
        wifi_popup:hide()
        bluetooth_popup:hide()
    end
end)

ram_popup:connect_signal("visibility", function(self, visible)
    if visible == true then
        cpu_popup:hide()
        disk_popup:hide()
        audio_popup:hide()
        wifi_popup:hide()
        bluetooth_popup:hide()
    end
end)

disk_popup:connect_signal("visibility", function(self, visible)
    if visible == true then
        cpu_popup:hide()
        ram_popup:hide()
        audio_popup:hide()
        wifi_popup:hide()
        bluetooth_popup:hide()
    end
end)

audio_popup:connect_signal("visibility", function(self, visible)
    if visible == true then
        cpu_popup:hide()
        ram_popup:hide()
        disk_popup:hide()
        wifi_popup:hide()
        bluetooth_popup:hide()
    end
end)

wifi_popup:connect_signal("visibility", function(self, visible)
    if visible == true then
        cpu_popup:hide()
        ram_popup:hide()
        audio_popup:hide()
        disk_popup:hide()
        bluetooth_popup:hide()
    end
end)

bluetooth_popup:connect_signal("visibility", function(self, visible)
    if visible == true then
        cpu_popup:hide()
        ram_popup:hide()
        audio_popup:hide()
        disk_popup:hide()
        wifi_popup:hide()
    end
end)

power_popup:connect_signal("visibility", function(visibility)
    for s in capi.screen do
        if visibility and s ~= awful.screen.focused() then
            s.screen_mask.visible = true
        end
        if visibility == false then
            s.screen_mask.visible = false
        end
    end
end)

lock_popup:connect_signal("visibility", function(visibility)
    for s in capi.screen do
        if visibility then
            if s ~= awful.screen.focused() then
                s.screen_mask.visible = true
            end
            s.left_wibar.ontop = false
            s.top_wibar.ontop = false
        else
            s.screen_mask.visible = false
            if #helpers.client.find({fullscreen = true}) == 0 then
                s.left_wibar.ontop = true
                s.top_wibar.ontop = true
            end
        end
    end
end)

power_popup:connect_signal("visibility", function(self, visibie)
    if visibie then
        for _, client in ipairs(capi.client.get()) do
            if client.fake_root ~= true then
                client.hidden = true
            end
        end
    else
        for _, client in ipairs(capi.client.get()) do
            client.hidden = false
        end
    end
end)

lock_popup:connect_signal("visibility", function(self, visibie)
    if visibie then
        for _, client in ipairs(capi.client.get()) do
            if client.fake_root ~= true then
                client.hidden = true
            end
        end
    else
        for _, client in ipairs(capi.client.get()) do
            client.hidden = false
        end
    end
end)

awful.screen.connect_for_each_screen(function(s)
    s.screen_mask = widgets.screen_mask(s)
end)

if DEBUG ~= true and helpers.misc.is_restart() == false then
    if theme_daemon:get_ui_show_lockscreen_on_login() then
        lock_popup:show()
    else
        require(... .. ".popups.loading")
    end
end