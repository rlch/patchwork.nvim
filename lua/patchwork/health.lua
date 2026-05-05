--- :checkhealth patchwork
---@module 'patchwork.health'
local M = {}

local h = vim.health or require("health")

function M.check()
  h.start("patchwork")

  local ok_main, main = pcall(require, "patchwork")
  if not ok_main then
    h.error("patchwork main module failed to load: " .. tostring(main))
    return
  end

  if not main.state.initialized then
    h.warn("patchwork.setup() has not been called")
  else
    h.ok("setup called (version " .. main.version:string() .. ")")
  end

  if main.state.server then
    h.ok("server running on port " .. tostring(main.state.port))
    if main.state.lock_file then
      h.ok("lockfile: " .. main.state.lock_file)
    else
      h.warn("server is running but no lockfile path is recorded")
    end
    if vim.env.CLAUDE_CODE_SSE_PORT then
      h.ok("CLAUDE_CODE_SSE_PORT=" .. vim.env.CLAUDE_CODE_SSE_PORT)
    else
      h.warn("CLAUDE_CODE_SSE_PORT is not set in this Neovim's env")
    end
    if main.is_claude_connected() then
      h.ok("at least one claude client is connected")
    else
      h.info("no claude client is currently connected — start `claude` in another pane")
    end
  else
    h.warn("server is not running — call require('patchwork').start() or :PatchworkStart")
  end

  if vim.fn.has("nvim-0.10") ~= 1 then
    h.warn("Neovim < 0.10 detected; patchwork is tested on 0.10+")
  else
    h.ok("Neovim version OK (" .. tostring(vim.version()) .. ")")
  end
end

return M
