--- patchwork — native Claude Code IDE bridge for Neovim.
---
--- Hosts a WebSocket+MCP server inside Neovim that the `claude` CLI auto-
--- discovers via lockfile + env vars (`CLAUDE_CODE_SSE_PORT`,
--- `ENABLE_IDE_INTEGRATION`). Designed for a multiplexer workflow: nvim in
--- one pane, `claude` in another, plugin bridges them.
---@module 'patchwork'
local M = {}

---@type PatchworkVersion
M.version = {
  major = 0,
  minor = 1,
  patch = 0,
  prerelease = nil,
  string = function(self)
    local s = string.format("%d.%d.%d", self.major, self.minor, self.patch)
    if self.prerelease then
      s = s .. "-" .. self.prerelease
    end
    return s
  end,
}

---@type PatchworkState
M.state = {
  config = nil,
  server = nil,
  port = nil,
  auth_token = nil,
  lock_file = nil,
  initialized = false,
}

local function logger()
  return require("patchwork.logger")
end

--- Whether at least one MCP client (i.e. `claude`) is currently connected.
---@return boolean
function M.is_claude_connected()
  if not M.state.server then
    return false
  end
  local ok, status = pcall(M.state.server.get_status)
  return ok and status.running and (status.client_count or 0) > 0
end

---Format a path for the `at_mentioned` notification: relative to cwd if
---possible, with a trailing slash for directories.
---@param file_path string
---@return string formatted
---@return boolean is_directory
local function format_path(file_path)
  assert(type(file_path) == "string" and file_path ~= "", "file_path must be a non-empty string")
  local is_directory = vim.fn.isdirectory(file_path) == 1
  local cwd = vim.fn.getcwd()
  local formatted = file_path
  if string.find(file_path, cwd, 1, true) == 1 then
    local rel = string.sub(file_path, #cwd + 2)
    if rel ~= "" then
      formatted = rel
    end
  end
  if is_directory and not string.match(formatted, "/$") then
    formatted = formatted .. "/"
  end
  return formatted, is_directory
end

---Push an `at_mentioned` JSON-RPC notification to all connected clients.
---@param file_path string Absolute path
---@param start_line integer? 0-indexed line number
---@param end_line integer? 0-indexed line number (inclusive)
---@param source string? Free-form context label for logs
---@return boolean success
---@return string? err
function M.send_at_mention(file_path, start_line, end_line, source)
  source = source or "command"
  if not M.state.server then
    logger().error(source, "patchwork is not running")
    return false, "patchwork is not running"
  end

  local ok, formatted, is_directory = pcall(format_path, file_path)
  if not ok then
    return false, tostring(formatted)
  end
  if is_directory and (start_line or end_line) then
    start_line, end_line = nil, nil
  end

  local params = {
    filePath = formatted,
    lineStart = start_line,
    lineEnd = end_line,
  }
  local broadcast_ok = M.state.server.broadcast("at_mentioned", params)
  if not broadcast_ok then
    return false, "Failed to broadcast at_mentioned for " .. formatted
  end
  return true
end

--- Hook called by the server module when a new client connects.
--- patchwork doesn't queue mentions (the multiplexer model assumes claude is
--- already running), so this is a no-op kept for vendored-server compat.
---@param from_new_connection boolean
function M.process_mention_queue(from_new_connection) end

--- Setup entry point — merges user opts and (optionally) auto-starts.
---@param user_opts table?
function M.setup(user_opts)
  if M.state.initialized then
    return
  end
  local config_mod = require("patchwork.config")
  local cfg = config_mod.apply(user_opts)
  config_mod.validate(cfg)
  M.state.config = cfg
  logger().setup(cfg)
  require("patchwork.diff").setup(cfg)
  M.state.initialized = true
  if cfg.auto_start then
    M.start()
  end
end

--- Start the WebSocket server, write the lockfile, export discovery env
--- vars, and enable selection tracking.
---@return boolean success
---@return string? error
function M.start()
  if not M.state.initialized then
    return false, "patchwork.setup() not called"
  end
  if M.state.server then
    return false, "patchwork is already running"
  end

  local server = require("patchwork.server")
  local lockfile = require("patchwork.lockfile")

  local auth_token = lockfile.generate_auth_token()
  local ok, port_or_err = server.start(M.state.config, auth_token)
  if not ok then
    logger().error("patchwork", "server failed to start:", port_or_err)
    return false, tostring(port_or_err)
  end
  ---@cast port_or_err integer
  M.state.server = server
  M.state.port = port_or_err
  M.state.auth_token = auth_token

  local lock_ok, lock_path_or_err = lockfile.create(port_or_err, auth_token)
  if not lock_ok then
    logger().error("patchwork", "lockfile create failed:", lock_path_or_err)
    server.stop()
    M.state.server = nil
    return false, tostring(lock_path_or_err)
  end
  M.state.lock_file = lock_path_or_err

  vim.env.CLAUDE_CODE_SSE_PORT = tostring(port_or_err)
  vim.env.ENABLE_IDE_INTEGRATION = "true"

  if M.state.config.track_selection then
    require("patchwork.selection").enable(server, M.state.config.visual_demotion_delay_ms)
  end

  logger().info("patchwork", "started — port=" .. port_or_err .. " lock=" .. lock_path_or_err)
  return true
end

--- Stop the server, remove the lockfile, clear env vars.
---@return boolean success
function M.stop()
  if not M.state.server then
    return false
  end
  pcall(require("patchwork.selection").disable)
  pcall(M.state.server.stop)

  if M.state.lock_file then
    pcall(require("patchwork.lockfile").remove, M.state.port)
  end

  vim.env.CLAUDE_CODE_SSE_PORT = nil
  vim.env.ENABLE_IDE_INTEGRATION = nil

  M.state.server = nil
  M.state.port = nil
  M.state.auth_token = nil
  M.state.lock_file = nil
  logger().info("patchwork", "stopped")
  return true
end

--- Return a status snapshot suitable for `:PatchworkStatus` and tests.
function M.status()
  if not M.state.server then
    return { running = false }
  end
  local s = M.state.server.get_status()
  s.port = M.state.port
  s.lock_file = M.state.lock_file
  s.version = M.version:string()
  return s
end

vim.api.nvim_create_autocmd("VimLeavePre", {
  group = vim.api.nvim_create_augroup("patchwork_shutdown", { clear = true }),
  callback = function()
    pcall(M.stop)
  end,
})

return M
