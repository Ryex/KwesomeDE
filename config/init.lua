-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------

print("LOADING [CONFIG]: Running '.startup'")
require(... .. ".startup")
print("LOADING [CONFIG]: Running '.apps'") -- pause
require(... .. ".apps")
print("LOADING [CONFIG]: Running '.layouts'")
require(... .. ".layouts")
print("LOADING [CONFIG]: Running '.tags'")
require(... .. ".tags")
print("LOADING [CONFIG]: Running '.keys'") -- BIG pause
require(... .. ".keys")
print("LOADING [CONFIG]: Running '.rules'")
require(... .. ".rules")
print("LOADING [CONFIG]: Running '.ranger'")
require(... .. ".ranger")

print("LOADING [CONFIG]: DONE")