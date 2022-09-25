-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------

local timed_load = require('helpers.timed_load')

--print("LOADING [CONFIG]: Running '.startup'")
timed_load.require(... .. ".startup")
--print("LOADING [CONFIG]: Running '.apps'") -- pause
timed_load.require(... .. ".apps")
--print("LOADING [CONFIG]: Running '.layouts'")
timed_load.require(... .. ".layouts")
--print("LOADING [CONFIG]: Running '.tags'")
timed_load.require(... .. ".tags")
--print("LOADING [CONFIG]: Running '.keys'") -- BIG pause
timed_load.require(... .. ".keys")
--print("LOADING [CONFIG]: Running '.rules'")
timed_load.require(... .. ".rules")
--print("LOADING [CONFIG]: Running '.ranger'")
timed_load.require(... .. ".ranger")

--print("LOADING [CONFIG]: DONE")