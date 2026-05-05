---@meta
--- Shared type definitions for patchwork.
--- This file is `---@meta` so it is consumed only by lua-language-server,
--- never required at runtime.

---@alias PatchworkLogLevel "error"|"warn"|"info"|"debug"|"trace"

---@class PatchworkDiffOpts
---@field layout? "inline"|"vertical"|"horizontal"  Diff style (default "inline")
---@field open_in_new_tab? boolean          Open diff in a new tab (vertical/horizontal only)
---@field keep_terminal_focus? boolean      Unused in patchwork (multiplexer mode)
---@field hide_terminal_in_new_tab? boolean Unused in patchwork
---@field on_new_file_reject? "keep_empty"|"close_window"

---@class PatchworkPortRange
---@field min integer
---@field max integer

---@class PatchworkConfig
---@field auto_start boolean
---@field log_level PatchworkLogLevel
---@field port_range PatchworkPortRange
---@field track_selection boolean
---@field visual_demotion_delay_ms integer
---@field connection_wait_delay integer
---@field connection_timeout integer
---@field queue_timeout integer
---@field diff_opts PatchworkDiffOpts
---@field disable_broadcast_debouncing? boolean
---@field enable_broadcast_debouncing_in_tests? boolean
---@field terminal? table  Unused in patchwork; tolerated for vendored-code compat

---@class PatchworkVersion
---@field major integer
---@field minor integer
---@field patch integer
---@field prerelease? string
---@field string fun(self: PatchworkVersion): string

---@class PatchworkState
---@field config PatchworkConfig?  Set by setup(); nil before then
---@field server table|nil       The server module when running
---@field port integer|nil
---@field auth_token string|nil
---@field lock_file string|nil
---@field initialized boolean
