-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------
local wibox = require("wibox")
local widgets = require("ui.widgets")
local beautiful = require("beautiful")
local weather_daemon = require("daemons.web.weather")
local helpers = require("helpers")
local dpi = beautiful.xresources.apply_dpi
local setmetatable = setmetatable
local tonumber = tonumber
local string = string
local ipairs = ipairs
local math = math
local os = os
local capi = {
    awesome = awesome
}

local weather = {
    mt = {}
}

local icon_map = {
    ["01d"] = beautiful.icons.sun, -- clear-sky
    ["02d"] = beautiful.icons.sun_cloud, -- few-clouds
    ["03d"] = beautiful.icons.cloud, -- scattered-clouds
    ["04d"] = beautiful.icons.cloud_sun, -- broken-clouds
    ["09d"] = beautiful.icons.cloud_sun_rain, -- shower-rain
    ["10d"] = beautiful.icons.raindrops, -- rain
    ["11d"] = beautiful.icons.cloud_bolt_sun, -- thunderstorm
    ["13d"] = beautiful.icons.snowflake, -- snow
    ["50d"] = beautiful.icons.cloud_fog, -- mist
    ["01n"] = beautiful.icons.moon, -- clear-sky-night
    ["02n"] = beautiful.icons.moon_cloud, -- few-clouds-night
    ["03n"] = beautiful.icons.cloud, -- scattered-clouds-night
    ["04n"] = beautiful.icons.cloud_moon, -- broken-clouds-night
    ["09n"] = beautiful.icons.cloud_moon_rain, -- shower-rain-night
    ["10n"] = beautiful.icons.raindrops, -- rain-night
    ["11n"] = beautiful.icons.cloud_bolt_moon, -- thunderstorm-night
    ["13n"] = beautiful.icons.snowflake, -- snow-night
    ["50n"] = beautiful.icons.cloud_fog -- mist-night
}

local function curvaceous(cr, x, y, b, step_width, options, draw_line)
    local interpolate = helpers.bezier.cubic_from_derivative_and_points_min_stretch

    local state = options.curvaceous_state
    if not state or state.last_group ~= options._group_idx then
        -- New data series is being drawn, reset state.
        state = {
            last_group = options._group_idx,
            x = x,
            y = y,
            b = b
        }
        options.curvaceous_state = state
        return
    end

    -- Compute if the bar needs to be cut due to spacing and how much
    local step_spacing = options._step_spacing
    local step_fraction = step_spacing ~= 0 and step_width / (step_width + step_spacing)

    -- Get coordinates from the previous step
    local x0, y0, b0 = state.x, state.y, state.b
    -- Update coordinates in state
    state.x, state.y, state.b = x, y, b
    -- Get derivatives from the previous step
    local y_d, b_d = state.y_d or 0, state.b_d or 0

    -- Guard against NaNs in the y coordinate
    y0 = (y0 == y0) and y0 or b0
    y = (y == y) and y or b

    -- Horizontal linear movement of the curves
    local x_curve = {helpers.bezier.cubic_through_points(x0, x0 + step_width)}

    -- Vertical movement curve for y
    local y_curve = {interpolate(y_d, y0, y)}
    state.y_d = helpers.bezier.curve_derivative_at_one(y_curve)
    if step_fraction then
        y_curve = helpers.bezier.curve_split_at(y_curve, step_fraction)
    end

    -- Paint the value curve
    cr:move_to(x_curve[1], y_curve[1])
    cr:curve_to(x_curve[2], y_curve[2], x_curve[3], y_curve[3], x_curve[4], y_curve[4])

    if not draw_line then
        -- Vertical movement curve for the baseline
        local b_curve = {interpolate(b_d, b0, b)}
        state.b_d = helpers.bezier.curve_derivative_at_one(b_curve)
        if step_fraction then
            b_curve = helpers.bezier.curve_split_at(b_curve, step_fraction)
        end

        -- Paint the bar bounded by the baseline curve from below
        cr:line_to(x_curve[4], b_curve[4])
        cr:curve_to(x_curve[3], b_curve[3], x_curve[2], b_curve[2], x_curve[1], b_curve[1])
        cr:close_path()
    end
end

local function to_direction(degrees)
    -- Ref: https://www.campbellsci.eu/blog/convert-wind-directions
    if degrees == nil then
        return "Unknown dir"
    end

    local directions = {"N", "NNE", "NE", "ENE", "E", "ESE", "SE", "SSE", "S", "SSW", "SW", "WSW", "W", "WNW", "NW",
                        "NNW", "N"}
    return directions[math.floor((degrees % 360) / 22.5) + 1]
end

local function celsius_to_fahrenheit(c)
    return c * 9 / 5 + 32
end

local function fahrenheit_to_celsius(f)
    return (f - 32) * 5 / 9
end

local function gen_temperature_str(temp, fmt_str, show_other_units, unit)
    local temp_str = string.format(fmt_str, temp)
    local s = temp_str .. "°" .. (unit == "metric" and "C" or "F")

    if (show_other_units) then
        local temp_conv, units_conv
        if (unit == "metric") then
            temp_conv = celsius_to_fahrenheit(temp)
            units_conv = "F"
        else
            temp_conv = fahrenheit_to_celsius(temp)
            units_conv = "C"
        end

        local temp_conv_str = string.format(fmt_str, temp_conv)
        s = s .. " " .. "(" .. temp_conv_str .. "°" .. units_conv .. ")"
    end

    return s
end

local function get_uvi_index_color(uvi)
    if uvi >= 0 and uvi < 3 then
        return beautiful.colors.green
    elseif uvi >= 3 and uvi < 6 then
        return beautiful.colors.yellow
    elseif uvi >= 6 and uvi < 8 then
        return beautiful.colors.magenta
    elseif uvi >= 8 and uvi < 11 then
        return beautiful.colors.red
    elseif uvi >= 11 then
        return beautiful.colors.bright_red
    end
end

local function new()
    local time_format_12h = false
    local both_units_widget = false

    local icon = wibox.widget {
        widget = widgets.text,
        size = 85,
    }

    local current_weather_widget = wibox.widget {
        layout = wibox.layout.flex.horizontal,
        {
            layout = wibox.layout.align.vertical,
            {
                widget = wibox.container.place,
                align = "center",
                icon
            },
            {
                widget = widgets.text,
                id = "description",
                halign = "center",
                size = 12
            }
        },
        {
            layout = wibox.layout.fixed.vertical,
            spacing = dpi(15),
            forced_width = 150,
            {
                layout = wibox.layout.fixed.vertical,
                {
                    widget = widgets.text,
                    id = "temp",
                    size = 40
                },
                {
                    widget = widgets.text,
                    id = "feels_like_temp",
                    halign = "left",
                    size = 12
                }
            },
            {
                layout = wibox.layout.align.vertical,
                expand = "inside",
                {
                    layout = wibox.layout.align.horizontal,
                    {
                        widget = widgets.text,
                        bold = true,
                        size = 12,
                        text = "Wind: ",
                    },
                    {
                        widget = widgets.text,
                        id = "wind",
                        size = 12
                    },
                },
                {
                    layout = wibox.layout.align.horizontal,
                    {
                        widget = widgets.text,
                        bold = true,
                        size = 12,
                        text = "Humidity: ",
                    },
                    {
                        widget = widgets.text,
                        id = "humidity",
                        size = 12
                    },
                },
                {
                    layout = wibox.layout.align.horizontal,
                    {
                        widget = widgets.text,
                        bold = true,
                        size = 12,
                        text = "UV: ",
                    },
                    {
                        widget = widgets.text,
                        id = "uv",
                        size = 12
                    },
                },
            }
        }
    }

    local temperatures = wibox.widget {
        layout = wibox.layout.flex.horizontal
    }

    local hourly_forecast_graph = wibox.widget {
        widget = wibox.widget.graph,
        forced_height = dpi(55),
        stack = false,
        scale = true,
        step_width = dpi(18),
        step_hook = curvaceous,
        background_color = beautiful.colors.transparent,
        color = helpers.color.darken(beautiful.icons.sun.color, 0.5),
        opacity = 1
    }

    local hourly_forecast_graph_border = wibox.widget {
        widget = wibox.widget.graph,
        forced_height = dpi(55),
        stack = false,
        scale = true,
        step_width = dpi(18),
        step_hook = curvaceous,
        background_color = beautiful.colors.transparent,
        color = beautiful.icons.sun.color,
        opacity = 1
    }

    capi.awesome.connect_signal("colorscheme::changed", function(old_colorscheme_to_new_map)
        hourly_forecast_graph.color = helpers.color.darken(beautiful.icons.sun.color, 0.5)
        hourly_forecast_graph_border.color = beautiful.icons.sun.color
    end)

    local hours = wibox.widget {
        layout = wibox.layout.flex.horizontal
    }

    local daily_forecast_widget = wibox.widget {
        layout = wibox.layout.flex.horizontal,
        spacing = dpi(5)
    }

    local spinning_circle = widgets.spinning_circle {
        forced_width = dpi(150),
        forced_height = dpi(150)
    }

    local missing_credentials_text = wibox.widget {
        widget = wibox.container.place,
        halign = "center",
        valign = "center",
        {
            widget = widgets.text,
            halign = "center",
            size = 25,
            color = beautiful.colors.on_background,
            text = "Missing Credentials"
        }
    }

    local error_icon = wibox.widget {
        widget = widgets.text,
        halign = "center",
        icon = beautiful.icons.circle_exclamation,
        size = 120
    }

    local weather_widget = wibox.widget {
        layout = wibox.layout.fixed.vertical,
        spacing = dpi(15),
        current_weather_widget,
        {
            layout = wibox.layout.overflow.horizontal,
            forced_width = dpi(500),
            scrollbar_widget = widgets.scrollbar,
            scrollbar_width = dpi(10),
            step = 50,
            {
                widget = wibox.container.margin,
                margins = {
                    bottom = dpi(15)
                },
                {
                    layout = wibox.layout.fixed.vertical,
                    spacing = dpi(15),
                    temperatures,
                    {
                        layout = wibox.layout.stack,
                        vertical_offset = dpi(5),
                        hourly_forecast_graph_border,
                        hourly_forecast_graph
                    },
                    hours,
                    daily_forecast_widget
                }
            }
        }
    }

    local stack = wibox.widget {
        layout = wibox.layout.stack,
        top_only = true,
        spinning_circle,
        missing_credentials_text,
        error_icon,
        weather_widget
    }

    weather_daemon:connect_signal("error", function()
        spinning_circle:stop()
        stack:raise_widget(error_icon)
    end)

    weather_daemon:connect_signal("error::missing_credentials", function()
        spinning_circle:stop()
        stack:raise_widget(missing_credentials_text)
    end)

    weather_daemon:connect_signal("weather", function(self, result)
        spinning_circle:stop()

        hours:reset()
        temperatures:reset()
        hourly_forecast_graph:clear()
        hourly_forecast_graph_border:clear()
        daily_forecast_widget:reset()

        stack:raise_widget(weather_widget)

        local weather = result.current
        icon:set_icon(icon_map[weather.weather[1].icon])
        current_weather_widget:get_children_by_id("temp")[1]:set_text(
            gen_temperature_str(weather.temp, "%.0f", both_units_widget, weather_daemon:get_unit()))
        current_weather_widget:get_children_by_id("feels_like_temp")[1]:set_text("Feels like " ..
            gen_temperature_str(weather.feels_like, "%.0f", false, weather_daemon:get_unit()))
        current_weather_widget:get_children_by_id("description")[1]:set_text(weather.weather[1].description)
        current_weather_widget:get_children_by_id("wind")[1]:set_text(
            weather.wind_speed .. "m/s (" .. to_direction(weather.wind_deg) .. ")")
        current_weather_widget:get_children_by_id("humidity")[1]:set_text(weather.humidity)
        current_weather_widget:get_children_by_id("uv")[1]:set_text(weather.uvi)
        current_weather_widget:get_children_by_id("uv")[1]:set_color(get_uvi_index_color(weather.uvi))

        for i, hour in ipairs(result.hourly) do
            hourly_forecast_graph:add_value(hour.temp)
            hourly_forecast_graph_border:add_value(hour.temp)

            if (i - 1) % 4 == 0 then
                local hour_widget = wibox.widget {
                    widget = widgets.text,
                    halign = "center",
                    size = 12,
                    text = os.date(time_format_12h and "%I%p" or "%H:00", tonumber(hour.dt))
                }

                local temperature_widget = wibox.widget {
                    widget = widgets.text,
                    halign = "center",
                    size = 15,
                    text = string.format("%.0f", hour.temp) .. "°"
                }

                hours:add(hour_widget)
                temperatures:add(temperature_widget)
            end
        end

        for _, day in ipairs(result.daily) do
            local day_forecast = wibox.widget {
                layout = wibox.layout.fixed.vertical,
                spacing = dpi(15),
                {
                    widget = widgets.text,
                    halign = "center",
                    size = 15,
                    text = os.date("%a", tonumber(day.dt) + tonumber(result.timezone_offset))
                },
                {
                    layout = wibox.layout.fixed.vertical,
                    spacing = dpi(8),
                    {
                        widget = widgets.text,
                        halign = "center",
                        icon = icon_map[day.weather[1].icon],
                        size = 35
                    },
                    {
                        widget = widgets.text,
                        forced_width = dpi(105),
                        halign = "center",
                        valign = "top",
                        size = 12,
                        text = day.weather[1].description
                    },
                    {
                        widget = widgets.text,
                        halign = "center",
                        size = 12,
                        text = gen_temperature_str(day.temp.day, "%.0f", false, weather_daemon:get_unit())
                    },
                    {
                        widget = widgets.text,
                        halign = "center",
                        size = 12,
                        text = gen_temperature_str(day.temp.night, "%.0f", false, weather_daemon:get_unit())
                    }
                }
            }

            daily_forecast_widget:add(day_forecast)
        end
    end)

    return stack
end

function weather.mt:__call(...)
    return new(...)
end

return setmetatable(weather, weather.mt)
