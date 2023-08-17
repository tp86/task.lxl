-- mod-version:3
local core = require "core"
local command = require "core.command"
local common = require "core.common"
local doc = require "core.doc"

local tasks = {}

local outputdoc = doc:extend()
function outputdoc:is_dirty()
  return false
end
function outputdoc:append(text)
  local line = #self.lines
  local col = #self.lines[line]
  self:insert(line, col, text)
end

local function run(name, task)
  core.log("Executing '%s' task", name)
  core.add_thread(function()
    local runner = process.start({ "sh", "-c", task .. " 2>&1" })
    local output = outputdoc("Task '"..name.."' output", nil, true)
    local start = system.get_time()
    local opened = false
    while runner:running() do
      local stdout = runner:read_stdout() or ""
      core.log("read bytes from stdout: %d", #stdout)
      output:append(stdout)
      if system.get_time() - start > 0.2 then
        core.root_view:open_doc(output)
        opened = true
      end
      coroutine.yield(0.05)
    end
    local returncode = runner:returncode()
    -- TODO handle errors and output
    if returncode == 0 then
      core.log("task ended successfully")
    else
      core.log("task failed")
    end
    if not opened then
      core.root_view:open_doc(output)
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
        run(item.text, item.task)
      end
    end,
    suggest = function(text)
      local res = common.fuzzy_match(tasknames, text)
      for i, name in ipairs(res) do
        local task = projecttasks[name]
        local info = task
        if #info > 64 then
          info = info:sub(1, 63) .. "…"
        end
        res[i] = {
          text = name,
          info = info,
          task = task,
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

local function runtask(name)
  local projecttasks = getprojecttasks()
  local task = projecttasks[name]
  if task then
    run(name, task)
  end
end

command.add(anyprojecttask, {
  ["task:run"] = selectandruntask,
})

return {
  add = addtasks,
  run = runtask,
}

