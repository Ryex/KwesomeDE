-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------

print("LOADING [PRESENTATION ui.widgets]: Starting load of widgets ...")
local widgets = {}

print("LOADING [PRESENTATION ui.widgets]: Getting '.battery_icon'")
widgets.battery_icon = require(... .. ".battery_icon")
print("LOADING [PRESENTATION ui.widgets]: Getting '.button'")
widgets.button = require(... .. ".button")
print("LOADING [PRESENTATION ui.widgets]: Getting '.calendar'")
widgets.calendar = require(... .. ".calendar")
print("LOADING [PRESENTATION ui.widgets]: Getting '.checkbox'")
widgets.checkbox = require(... .. ".checkbox")
print("LOADING [PRESENTATION ui.widgets]: Getting '.container'")
widgets.container = require(... .. ".container")
print("LOADING [PRESENTATION ui.widgets]: Getting '.dropdown'")
widgets.dropdown = require(... .. ".dropdown")
print("LOADING [PRESENTATION ui.widgets]: Getting '.graph'")
widgets.graph = require(... .. ".graph")
print("LOADING [PRESENTATION ui.widgets]: Getting '.menu'")
widgets.menu = require(... .. ".menu")
print("LOADING [PRESENTATION ui.widgets]: Getting '.overflow'")
widgets.overflow = require(... .. ".overflow")
print("LOADING [PRESENTATION ui.widgets]: Getting '.playerctl'") -- big pause
widgets.playerctl = require(... .. ".playerctl")
print("LOADING [PRESENTATION ui.widgets]: Getting '.prompt'")
widgets.prompt = require(... .. ".prompt")
print("LOADING [PRESENTATION ui.widgets]: Getting '.screen_mask'")
widgets.screen_mask = require(... .. ".screen_mask")
print("LOADING [PRESENTATION ui.widgets]: Getting '.slider'")
widgets.slider = require(... .. ".slider")
print("LOADING [PRESENTATION ui.widgets]: Getting '.spacer'")
widgets.spacer = require(... .. ".spacer")
print("LOADING [PRESENTATION ui.widgets]: Getting '.spinning_circle'")
widgets.spinning_circle = require(... .. ".spinning_circle")
print("LOADING [PRESENTATION ui.widgets]: Getting '.text'")
widgets.text = require(... .. ".text")

print("LOADING [PRESENTATION ui.widgets]: DONE")

return widgets