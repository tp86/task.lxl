-- mod-version:3
local core = require "core"
local command = require "core.command"

local tasks = {}

local function runtask(command)
  -- execute command (in separate process)
  -- handle errors and output
end

local function selectandruntask(projecttasks)
  -- enter command line with project task names as suggestion
end

local function getprojecttasks()
  local projectdir = core.project_dir
  return tasks[projectdir] or {}
end

local function addtasks(taskstoadd)
  local projecttasks = getprojecttasks()
  for name, command in pairs(taskstoadd) do
    projecttasks[name] = command
  end
  tasks[projectdir] = projecttasks
end

local function anyprojecttask()
  local projecttasks = getprojecttasks()
  return next(projecttasks) ~= nil, projecttasks
end

command.add(anyprojecttask, {
  ["task:run"] = runtask,
})

return {
  add = addtasks,
}

