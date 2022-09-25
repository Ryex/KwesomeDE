local timed_load = require('helpers.timed_load')

return
{
    bezier = timed_load.require(... .. ".bezier"),
    client = timed_load.require(... .. ".client"),
    color = timed_load.require(... .. ".color"),
    filesystem = timed_load.require(... .. ".filesystem"),
    input = timed_load.require(... .. ".input"),
    inspect = timed_load.require(... .. ".inspect"),
    json = timed_load.require(... .. ".json"),
    layout = timed_load.require(... .. ".layout"),
    misc = timed_load.require(... .. ".misc"),
    run = timed_load.require(... .. ".run"),
    string = timed_load.require(... .. ".string"),
    table = timed_load.require(... .. ".table"),
    ui = timed_load.require(... .. ".ui")
}