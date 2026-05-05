--- Default configuration + merge helper.
---@module 'patchwork.config'
local M = {}

---@type PatchworkConfig
M.defaults = {
  auto_start = true,
  log_level = "info",
  port_range = { min = 10000, max = 65535 },

  -- Selection tracking
  track_selection = true,
  visual_demotion_delay_ms = 50,

  -- @-mention queue timing (mostly inert in the multiplexer flow,
  -- since claude is expected to be already connected, but kept for
  -- compatibility with vendored selection/at-mention plumbing).
  connection_wait_delay = 600,
  connection_timeout = 10000,
  queue_timeout = 5000,

  diff_opts = {
    layout = "inline", -- "inline" (VSCode/GitHub unified) | "vertical" | "horizontal"
    open_in_new_tab = false,
    keep_terminal_focus = false,
    hide_terminal_in_new_tab = false,
    on_new_file_reject = "keep_empty",
  },
}

---Merge user opts on top of defaults using deep-extend "force" semantics.
---@param user_opts table?
---@return PatchworkConfig
function M.apply(user_opts)
  return vim.tbl_deep_extend("force", vim.deepcopy(M.defaults), user_opts or {})
end

---Validate a fully-merged config. Throws on invalid values.
---@param config PatchworkConfig
function M.validate(config)
  assert(type(config.auto_start) == "boolean", "auto_start must be a boolean")
  assert(type(config.log_level) == "string", "log_level must be a string")
  assert(
    type(config.port_range) == "table"
      and type(config.port_range.min) == "number"
      and type(config.port_range.max) == "number"
      and config.port_range.min > 0
      and config.port_range.max <= 65535
      and config.port_range.min <= config.port_range.max,
    "invalid port_range"
  )
  assert(type(config.track_selection) == "boolean", "track_selection must be a boolean")
  assert(type(config.diff_opts) == "table", "diff_opts must be a table")
end

return M
