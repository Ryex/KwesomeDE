-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------

--print("LOADING [PRESENTATION ui.widgets]: Starting load of widgets ...")
local widgets = {}

local timed_load = require('helpers.timed_load')

--print("LOADING [PRESENTATION ui.widgets]: Getting '.battery_icon'")
widgets.battery_icon = timed_load.require(... .. ".battery_icon")
--print("LOADING [PRESENTATION ui.widgets]: Getting '.button'")
widgets.button = timed_load.require(... .. ".button")
--print("LOADING [PRESENTATION ui.widgets]: Getting '.calendar'")
widgets.calendar = timed_load.require(... .. ".calendar")
--print("LOADING [PRESENTATION ui.widgets]: Getting '.checkbox'")
widgets.checkbox = timed_load.require(... .. ".checkbox")
--print("LOADING [PRESENTATION ui.widgets]: Getting '.container'")
widgets.container = timed_load.require(... .. ".container")
--print("LOADING [PRESENTATION ui.widgets]: Getting '.dropdown'")
widgets.dropdown = timed_load.require(... .. ".dropdown")
--print("LOADING [PRESENTATION ui.widgets]: Getting '.graph'")
widgets.graph = timed_load.require(... .. ".graph")
--print("LOADING [PRESENTATION ui.widgets]: Getting '.menu'")
widgets.menu = timed_load.require(... .. ".menu")
--print("LOADING [PRESENTATION ui.widgets]: Getting '.overflow'")
widgets.overflow = timed_load.require(... .. ".overflow")
--print("LOADING [PRESENTATION ui.widgets]: Getting '.playerctl'") -- big pause
widgets.playerctl = timed_load.require(... .. ".playerctl")
--print("LOADING [PRESENTATION ui.widgets]: Getting '.prompt'")
widgets.prompt = timed_load.require(... .. ".prompt")
--print("LOADING [PRESENTATION ui.widgets]: Getting '.screen_mask'")
widgets.screen_mask = timed_load.require(... .. ".screen_mask")
--print("LOADING [PRESENTATION ui.widgets]: Getting '.slider'")
widgets.slider = timed_load.require(... .. ".slider")
--print("LOADING [PRESENTATION ui.widgets]: Getting '.spacer'")
widgets.spacer = timed_load.require(... .. ".spacer")
--print("LOADING [PRESENTATION ui.widgets]: Getting '.spinning_circle'")
widgets.spinning_circle = timed_load.require(... .. ".spinning_circle")
--print("LOADING [PRESENTATION ui.widgets]: Getting '.text'")
widgets.text = timed_load.require(... .. ".text")

--print("LOADING [PRESENTATION ui.widgets]: DONE")

return widgets