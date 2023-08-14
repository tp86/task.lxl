-- mod-version:3
local core = require "core"
local command = require "core.command"

local tasks = {}

local function runtask(projecttasks)
  for _, task in ipairs(projecttasks) do
    core.log("task: %s", task)
  end
end

local function addtasks(taskstoadd)
  local projectdir = core.project_dir
  local projecttasks = tasks[projectdir] or {}
  for _, task in ipairs(taskstoadd) do
    table.insert(projecttasks, task)
  end
  tasks[projectdir] = projecttasks
end

local function anyprojecttask()
  local projectdir = core.project_dir
  local projecttasks = tasks[projectdir] or {}
  return #projecttasks > 0, projecttasks
end

command.add(anyprojecttask, {
  ["task:run"] = runtask,
})

return {
  add = addtasks,
}

