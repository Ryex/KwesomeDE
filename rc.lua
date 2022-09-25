-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------

pcall(require, "luarocks.loader")


--print("LOADING [RC]: Getting Gears Timer")
local gtimer = require("gears.timer")

--print("LOADING [RC]: Getting 'beautiful'")
local beautiful = require("beautiful")

local timed_load = require('helpers.timed_load')
timed_load.setup_debug({
    debug = true,
    memory = true,
})

local collectgarbage = collectgarbage

--- Enable for lower memory consumption and faster loading
collectgarbage("setpause", 110)
collectgarbage("setstepmul", 1000)
gtimer({
	timeout = 5,
	autostart = true,
	call_now = true,
	callback = function()
		collectgarbage("collect")
	end,
})


local helpers = timed_load.require("helpers")



local presentation_dir = helpers.filesystem.get_awesome_config_dir("presentation")
print("LOADING [RC]: Setting up theme from " .. presentation_dir)
beautiful.init( presentation_dir .. "theme/theme.lua")

timed_load.require("config")

timed_load.require("presentation")

print("LOADING [RC]: DONE")

timed_load.print_load_times()
timed_load.save_load_results("./loadtimes.csv")