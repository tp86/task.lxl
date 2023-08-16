-- mod-version:3
local core = require "core"
local command = require "core.command"
local common = require "core.common"

local tasks = {}

local function runtask(command)
  core.log("Executing task command: '%s'", command)
  -- execute command (in separate process, reuse console plugin?)
  core.add_thread(function()
    local runner = process.start({ "sh", "-c", command })
    while runner:running() do
      coroutine.yield(0.05)
    end
    local returncode = runner:returncode()
    -- TODO handle errors and output
    if returncode == 0 then
      local stdout = runner:read_stdout() or ""
      core.log_quiet("task output: '%s'", stdout)
    else
      local stderr = runner:read_stderr() or ""
      core.log_quiet("task error: '%s'", stderr)
    end
  end)
end

local function selectandruntask(projecttasks)
  local tasknames = {}
  for name in pairs(projecttasks) do
    table.insert(tasknames, name)
  end
  core.command_view:enter("Select task to run", {
    submit = function(text, item)
      if item then
        runtask(item.command)
      end
    end,
    suggest = function(text)
      local res = common.fuzzy_match(tasknames, text)
      for i, name in ipairs(res) do
        local command = projecttasks[name]
        local info = command
        if #info > 64 then
          info = info:sub(1, 63) .. "…"
        end
        res[i] = {
          text = name,
          info = info,
          command = command,
        }
      end
      return res
    end
  })
end

local function getprojecttasks()
  local projectdir = core.project_dir
  local projecttasks = tasks[projectdir]
  if not projecttasks then
    projecttasks = {}
    tasks[projectdir] = projecttasks
  end
  return projecttasks
end

local function addtasks(taskstoadd)
  local projecttasks = getprojecttasks()
  for name, command in pairs(taskstoadd) do
    projecttasks[name] = command
  end
end

local function anyprojecttask()
  local projecttasks = getprojecttasks()
  return next(projecttasks) ~= nil, projecttasks
end

command.add(anyprojecttask, {
  ["task:run"] = selectandruntask,
})

return {
  add = addtasks,
}

