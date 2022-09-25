-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------
local timed_load = require('helpers.timed_load')

return
{
	elevated = timed_load.require("presentation.ui.widgets.button.elevated"),
	image = timed_load.require("presentation.ui.widgets.button.image"),
	text = timed_load.require("presentation.ui.widgets.button.text")
}