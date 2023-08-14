-- mod-version:3
local core = require "core"
local command = require "core.command"

local function runtask()
  core.log("running task")
end

command.add(true, {
  ["task:run"] = runtask,
})

