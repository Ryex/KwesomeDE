-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------

pcall(require, "luarocks.loader")

--print("LOADING [RC]: Getting Gears Timer")
local gtimer = require("gears.timer")

--print("LOADING [RC]: Getting 'beautiful'")
local beautiful = require("beautiful")

--print("LOADING [RC]: Getting 'load'")
local timed_load = require('timed_load')
timed_load:setup_debug(true)

--print("LOADING [RC]: Getting 'helpers'")
local helpers = timed_load:require("helpers")

local collectgarbage = collectgarbage

--print("LOADING [RC]: Setting up garbage collection")
collectgarbage("setpause", 100)
collectgarbage("setstepmul", 400)


local presentation_dir = helpers.filesystem.get_awesome_config_dir("presentation")
print("LOADING [RC]: Setting up theme from " .. presentation_dir)
beautiful.init( presentation_dir .. "theme/theme.lua")

--print("LOADING [RC]: Getting 'config'")
timed_load:require("config")

--print("LOADING [RC]: Getting 'presentation'")
timed_load:require("presentation")

gtimer { timeout = 5, autostart = true, call_now = true, callback = function()
    collectgarbage("collect")
end }

--print("LOADING [RC]: DONE")

timed_load:print_load_times()
timed_load:save_load_results("./loadtimes.csv")