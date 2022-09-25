local gears = require("gears")

local debug = {}

function debug.dump(msg, data, depth)
    gears.debug.dump(data, msg, depth)
end

function debug.log(str, ...)
    print(string.format(str, ...))
end

local time = {}
debug.time = time

function time.now()
  return {
    sec = os.time(),
    clk = os.clock()
  }
end

function time.time_diff(start, finish)
  return {
    sec = finish.sec - start.sec,
    clk = finish.clk - start.clk
  }
end

function time.since(start)
    return time.time_diff(start, time.now())
end

function time.call(msg, func, ...)
    print(string.format("DEBUG | Timed Call: '%s' starting", msg))
    local s = time.now()
    local ret = func(...)
    local t = time.since(s)
    print(string.format("DEBUG | Timed Call: '%s' finished in %f ms", msg, t.clk * 1000))
    return ret
end

function time.stopwatch()
    local sw = {
        laps = {}
    }
    function sw:start()
        self._start = time.now()
        self._last = self._start
        self.laps = {}
    end

    function sw:lap()
        local l = time.since(self._last)
        self._last = time.now()
        table.insert(self.laps, l)
        return l
    end

    return sw
end

return debug
