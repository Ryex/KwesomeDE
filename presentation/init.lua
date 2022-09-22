print("LOADING [PRESENTATION]: Running '.ui.apps.welcome'")
require(... .. ".ui.apps.welcome")

print("LOADING [PRESENTATION]: Running '.ui.desktop'")
require(... .. ".ui.desktop")

print("LOADING [PRESENTATION]: Running '.ui.popups.brightness'")
require(... .. ".ui.popups.brightness")
print("LOADING [PRESENTATION]: Running '.ui.popups.keyboard_layout'")
require(... .. ".ui.popups.keyboard_layout")
print("LOADING [PRESENTATION]: Running '.ui.popups.layout_switcher'")
require(... .. ".ui.popups.layout_switcher")
print("LOADING [PRESENTATION]: Running '.ui.popups.loading'")
require(... .. ".ui.popups.loading")
print("LOADING [PRESENTATION]: Running '.ui.popups.lock'")
require(... .. ".ui.popups.lock")
print("LOADING [PRESENTATION]: Running '.ui.popups.tag_preview'")
require(... .. ".ui.popups.tag_preview")
print("LOADING [PRESENTATION]: Running '.ui.popups.volume'")
require(... .. ".ui.popups.volume")
print("LOADING [PRESENTATION]: Running '.ui.popups.window_switcher'")
require(... .. ".ui.popups.window_switcher")

print("LOADING [PRESENTATION]: Running '.ui.notifications'")
require(... .. ".ui.notifications")

print("LOADING [PRESENTATION]: Running '.ui.titlebar'")
require(... .. ".ui.titlebar")

print("LOADING [PRESENTATION]: Running '.ui.wibar'")
require(... .. ".ui.wibar")

print("LOADING [PRESENTATION]: Getting '.ui.panels.action'")
local action_panel = require(... .. ".ui.panels.action")
print("LOADING [PRESENTATION]: Getting '.ui.panels.info'")
local info_panel = require(... .. ".ui.panels.info")
print("LOADING [PRESENTATION]: Getting '.ui.panels.message'")
local message_panel = require(... .. ".ui.panels.message")

print("LOADING [PRESENTATION]: Getting '.ui.popups.power'")
local power_popup = require(... .. ".ui.popups.power")

print("LOADING [PRESENTATION]: Getting '.ui.applets.cpu'")
local cpu_popup = require(... .. ".ui.applets.cpu")
print("LOADING [PRESENTATION]: Getting '.ui.applets.ram'")
local ram_popup = require(... .. ".ui.applets.ram")
print("LOADING [PRESENTATION]: Getting '.ui.applets.disk'")
local disk_popup = require(... .. ".ui.applets.disk")
print("LOADING [PRESENTATION]: Getting '.ui.applets.audio'")
local audio_popup = require(... .. ".ui.applets.audio")
print("LOADING [PRESENTATION]: Getting '.ui.applets.wifi'")
local wifi_popup = require(... .. ".ui.applets.wifi")
print("LOADING [PRESENTATION]: Getting '.ui.applets.bluetooth'")
local bluetooth_popup = require(... .. ".ui.applets.bluetooth")


print("LOADING [PRESENTATION]: connect signals  ")
local capi = { client = client }

capi.client.connect_signal("property::fullscreen", function(c)
    if c.fullscreen then
        action_panel:hide()
        info_panel:hide()
        message_panel:hide()
        cpu_popup:hide()
        ram_popup:hide()
        disk_popup:hide()
        audio_popup:hide()
        wifi_popup:hide()
        bluetooth_popup:hide()
    end
end)

capi.client.connect_signal("focus", function(c)
    if c.fullscreen then
        action_panel:hide()
        info_panel:hide()
        message_panel:hide()
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
        message_panel:hide()
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

message_panel:connect_signal("visibility", function(self, visible)
    if visible == true then
        action_panel:hide()
        power_popup:hide()
    end
end)

power_popup:connect_signal("visibility", function(self, visible)
    if visible == true then
        action_panel:hide()
        info_panel:hide()
        message_panel:hide()
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

print("LOADING [PRESENTATION]: DONE")