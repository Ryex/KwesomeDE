--- A require wraper that tracks load times and require stack


local gears = require("gears")
local gobject = require("gears.object")
local gtable = require("gears.table")
local posix = require("posix")

Stack = {}

-- Create a Table with stack functions
function Stack:Create()

  -- stack table
  local t = {}
  -- entry table
  t._et = {}

  -- push a value on to the stack
  function t:push(...)
    if ... then
      local targs = {...}
      -- add values
      for _,v in ipairs(targs) do
        table.insert(self._et, v)
      end
    end
  end

  -- pop a value from the stack
  function t:pop(num)

    -- get num values from stack
    local num = num or 1

    -- return table
    local entries = {}

    -- get values into entries
    for i = 1, num do
      -- get last entry
      if #self._et ~= 0 then
        table.insert(entries, self._et[#self._et])
        -- remove last value
        table.remove(self._et)
      else
        break
      end
    end
    -- return unpacked entries
    return table.unpack(entries)
  end

  -- get entries
  function t:getn()
    return #self._et
  end

  -- list values
  function t:print()
    for i,v in pairs(self._et) do
      print(i, v)
    end
  end

  function t:stack()
    return gears.table.clone(self._et)
  end

  return t
end


local load = { }
local instance = nil

local _DEBUG_LOADING = false
local _DEBUG_FIRST_ONLY = true

local _LOAD_WITH_TIMES = {}
local _LUA_LOAD_TIME = os.time()
local _LUA_LOAD_CLOCK = os.clock()

local _require_stack = Stack:Create()
local _require_call = 0
local _require_cached = 0
local _require_loads = 0

local Time = {}

local function lua_now()
  return {
    sec = os.time(),
    clk = os.clock()
  }
end


local function posix_now()
  if posix ~= nil then
    local s, ns = posix.clock_gettime(0)
    return {sec = s, nsec = ns}
  else
    return nil
  end
end


local function now()
  return {
    lua = lua_now(),
    posix = posix_now()
  }
end

local function time_diff(start, finish)
  local diff = {
    lua = {
      sec = finish.lua.sec - start.lua.sec,
      clk = finish.lua.clk - start.lua.clk
    },
    posix = nil
  }
  if start.posix ~= nil and finish.posix ~= nil then
    diff.posix = {
      sec = finish.posix.sec - start.posix.sec,
      nsec = finish.posix.nsec - start.posix.nsec
    }
  end
  return diff
end


function load:new(path)
  return {
    path = path,
    module = nil,
    _start = now(),
    _finish = nil,
    _load_time = nil,
    _load_order = _require_loads,
    _stack = _require_stack:stack()
  }
end


function load:require(path)

  _require_call = _require_call + 1

  if _LOAD_WITH_TIMES[path] ~= nil then
    if _DEBUG_LOADING and not _DEBUG_FIRST_ONLY then
      print(string.format("LOADING: require %s | CACHED", path))
    end
    _require_cached = _require_cached + 1
    return _LOAD_WITH_TIMES[path].module
  end

  if _DEBUG_LOADING then
    print(string.format("LOADING: require %s | FIRST LOAD", path))
  end

  _require_loads = _require_loads + 1

  local m = load.new(path)
  _require_stack:push(path)
  m.module = require(path)
  m._finish = now()
  _require_stack:pop()

  m._load_time = time_diff(m._start, m._finish)

  _LOAD_WITH_TIMES[path] = m

  if _DEBUG_LOADING then
    print(string.format("LOADING: FINISHED require %s", path))
  end

  return m.module

end

local _load_results = nil

local function prep_results(reset)

  reset = reset or false

  if _load_results ~= nil and not reset then
    return true
  end

  _load_results = {
    results = {},
    max_path_len = 0,
    max_stack_len = 0,
    out = {}
  }

  function _load_results:update(path, args)
    if self.results[path] == nil then
      self.results[path] = {}
    end
    gtable.crush(self.results[path], args)
  end

  return false
end

local function calc_load_results(recalc)
  recalc = recalc or false

  if prep_results(recalc) then
    return true
  end

  for path, val in pairs(_LOAD_WITH_TIMES) do

    local path_len = #path
    if path_len > _load_results.max_path_len then
      _load_results.max_path_len = path_len
    end

    local stack_len = #val._stack
    if stack_len > _load_results.max_stack_len then
      _load_results.max_stack_len = stack_len
    end

    _load_results:update(path, {
      path = path,
      stack = val._stack,
      order = val._load_order,
      load_time = -1,
      total_time = -1,
      req_time = 0,
      _load_time = val._load_time,
    })

    local was_req = #val._stack > 0
    if was_req then
      local req_by = val._stack[#val._stack]
      _load_results:update(path, {
        req_by = req_by
      })
    end
  end

  for path, _ in pairs(_LOAD_WITH_TIMES) do
    local req_by = _load_results.results[path].req_by
    if req_by ~= nil then
      local req_time =  _load_results.results[req_by].req_time or 0
      local load_time = _load_results.results[path]._load_time.lua.clk * 1000
      _load_results:update(req_by, {
        req_time = req_time + load_time
      })
    end
  end

  for _, val in pairs(_load_results.results) do
    val.total_time = val._load_time.lua.clk * 1000
    val.load_time = val.total_time - val.req_time

    _load_results.out[val.order] = val
  end

  return false
end

local function print_header(padding)
  print(string.format("Order | Path%s | %14s | %14s | %14s | %s",
    string.rep(" ", padding - 4), "Load", "Require", "Total", "Required First By"))
    local fill = string.rep("-", 14)
    print(string.format(":-----|--%s|-%s:|-%s:|-%s:|-%s",
      string.rep("-", padding), fill, fill, fill, string.rep("-", 20)))
end

local function print_load_time(order, path, loadt, reqt, totalt, req_by, padding, indent)
  local ins = string.rep("~ ", indent)
  local outs = string.rep(" ", padding - #path - (indent * 2))
  print(string.format("%-5d | %s%s%s | %12.5fms | %12.5fms | %12.5fms | %s",
    order, ins, path, outs, loadt, reqt, totalt, req_by))
end

function load:print_load_times(recalc)

  recalc = recalc or false

  calc_load_results(recalc)

  local padding = _load_results.max_path_len + (_load_results.max_stack_len * 2)

  print_header(padding)
  for _, result in ipairs(_load_results.out) do
    print_load_time(
      result.order,
      result.path,
      result.load_time,
      result.req_time,
      result.total_time,
      result.req_by or "",
      padding,
      #result.stack
    )
  end
end

function load:save_load_results(save_path, recalc)
  recalc = recalc or false

  calc_load_results(recalc)

  print(string.format("LOADING: Saving results to '%s'", save_path))

  local file = assert(io.open(save_path, "w"))
  file:write('Order, Path,  Load, Require, Total, Required First By')
  file:write('\n')
  for k, v in pairs(_load_results.out) do
    file:write(string.format("%d, %s, %f, %f, %f, %s", v.order, v.path, v.load_time, v.req_time, v.total_time, v.req_by))
    file:write('\n')
  end
  file:close()

end

function load:setup_debug(debug, first_only)
  debug = debug or false
  first_only = first_only or true

  _DEBUG_LOADING = debug
  _DEBUG_FIRST_ONLY = first_only
end

local function new()
  local ret = gobject{}
  gtable.crush(ret, load, true)

  return ret
end

if not instance then
  instance = new()
end

return instance