-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------

local gobject = require("gears.object")
local gtable = require("gears.table")
local gtimer = require("gears.timer")

local timed_load = require('helpers.timed_load')
local debugh = require("helpers.debug")

local settings = timed_load.require("services.settings")
local helpers = timed_load.require("helpers")
local string = string

local weather = { }
local instance = nil

local path = helpers.filesystem.get_cache_dir("weather")
local DATA_PATH_FORCAST = path .. "data_forcast.json"
local DATA_PATH_CURRENT = path .. "data_current.json"

local UPDATE_INTERVAL = 60 * 60 * 12 -- 12 hours

function weather:set_api_key(api_key)
    self._private.api_key = api_key
    settings:set_value("weather.api_key", self._private.api_key)
end

function weather:get_api_key()
    return self._private.api_key
end

function weather:set_unit(unit)
    self._private.unit = unit
    settings:set_value("weather.unit", self._private.unit)
end

function weather:get_unit()
    return self._private.unit
end

function weather:set_coordinate_lat(coordinate_lat)
    self._private.coordinate_lat = coordinate_lat
    settings:set_value("weather.coordinate_lat", self._private.coordinate_lat)
end

function weather:get_coordinate_lat()
    return self._private.coordinate_lat
end

function weather:set_coordinate_lon(coordinate_lon)
    self._private.coordinate_lon = coordinate_lon
    settings:set_value("weather.coordinate_lon", self._private.coordinate_lon)
end

function weather:get_coordinate_lon()
    return self._private.coordinate_lon
end

function weather:refresh()
    if self._private.mode == "forcast" then
        local link_forcast = string.format("https://api.openweathermap.org/data/2.5/onecall?lat=%s&lon=%s&appid=%s&units=%s&exclude=minutely&lang=en",
            self._private.coordinate_lat,
            self._private.coordinate_lon,
            self._private.api_key,
            self._private.unit)
    

        helpers.filesystem.remote_watch(
            DATA_PATH_FORCAST,
            link_forcast,
            UPDATE_INTERVAL,
            function(content)
                if content == nil or content == false then
                    self:emit_signal("error_forcast")
                    self:emit_signal("error")
                    return
                end

                local data = helpers.json.decode(content)
                if data == nil then
                    self:emit_signal("error_forcast")
                    self:emit_signal("error")
                    return
                end

                self:emit_signal("weather_forcast", data, self._private.unit)
            end
        )
    elseif self._private.mode == "current_loc" or self._private.mode == "current_lat_lon" then
        local link_current = ""
        if self._private.mode == "current_loc" then
            link_current = string.format("https://api.openweathermap.org/data/2.5/weather?q=%s&appid=%s&units=%s&lang=en",
                self._private.location,
                self._private.api_key,
                self._private.unit)
        else -- if self._private.mode == "current_lat_lon" then
            link_current = string.format("https://api.openweathermap.org/data/2.5/weather?lat=%s&lon=%s&appid=%s&units=%s&lang=en",
                self._private.coordinate_lat,
                self._private.coordinate_lon,
                self._private.api_key,
                self._private.unit)
        end

        helpers.filesystem.remote_watch(
            DATA_PATH_CURRENT,
            link_current,
            UPDATE_INTERVAL,
            function(content)
                if content == nil or content == false then
                    self:emit_signal("error_current")
                    self:emit_signal("error")
                    return
                end

                local data = helpers.json.decode(content)
                if data == nil then
                    self:emit_signal("error_current")
                    self:emit_signal("error")
                    return
                end

                self:emit_signal("weather_current", data, self._private.unit)
            end
        )
    else
        debugh.log("DEBUG [daemons.web.weather] | unknown mode for weather daemon '%s'", self._private.mode)
        self:emit_signal("error")
    end

end

local function new()
    local ret = gobject{}
    gtable.crush(ret, weather, true)

    ret._private = {}

    -- "metric" for Celcius, "imperial" for Fahrenheit
    ret._private.unit = settings:get_value("weather.unit") or "metric"
    ret._private.api_key = settings:get_value("weather.api_key")
    ret._private.location = settings:get_value("weather.location")
    ret._private.mode = settings:get_value("weather.mode")
    ret._private.coordinate_lat = settings:get_value("weather.coordinate_lat")
    ret._private.coordinate_lon = settings:get_value("weather.coordinate_lon")

    if ret._private.api_key ~= nil and ret._private.coordinate_lat ~= nil and ret._private.coordinate_lon ~= nil then
        ret:refresh()
    else
        gtimer.delayed_call(function()
            ret:emit_signal("missing_credentials")
        end)
    end

    return ret
end

if not instance then
    instance = new()
end
return instance