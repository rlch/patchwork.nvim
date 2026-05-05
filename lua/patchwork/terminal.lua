--- No-op terminal stub.
---
--- The upstream claudecode.nvim ships a terminal manager that launches the
--- `claude` CLI inside a Neovim split and tracks its bufnr so selection /
--- diff code can refocus it. patchwork is designed for a multiplexer workflow
--- (claude runs in a separate tmux/zellij pane), so there is no in-Neovim
--- claude terminal to track.
---
--- Vendored modules `pcall(require, "patchwork.terminal")` defensively, so we
--- only need to expose the two functions they actually call.
---@module 'patchwork.terminal'
local M = {}

--- @return integer|nil bufnr Always nil — no in-editor claude terminal exists.
function M.get_active_terminal_bufnr()
  return nil
end

--- No-op: the claude pane is owned by the multiplexer.
function M.ensure_visible() end

return M
