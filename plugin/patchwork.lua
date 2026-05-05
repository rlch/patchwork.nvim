-- patchwork plugin entry — runs once at startup.
-- Keep this minimal: version guard + user commands only. All real work
-- happens in lua/patchwork/init.lua via setup().

if vim.g.loaded_patchwork == 1 then
  return
end
vim.g.loaded_patchwork = 1

if vim.fn.has("nvim-0.10") ~= 1 then
  vim.notify("patchwork requires Neovim >= 0.10", vim.log.levels.ERROR)
  return
end

local function lazy_main()
  return require("patchwork")
end

vim.api.nvim_create_user_command("PatchworkStart", function()
  local ok, err = lazy_main().start()
  if not ok then
    vim.notify("PatchworkStart: " .. tostring(err), vim.log.levels.ERROR)
  end
end, { desc = "Start patchwork WebSocket server + write lockfile" })

vim.api.nvim_create_user_command("PatchworkStop", function()
  lazy_main().stop()
end, { desc = "Stop patchwork and remove the lockfile" })

vim.api.nvim_create_user_command("PatchworkStatus", function()
  local s = lazy_main().status()
  vim.notify(vim.inspect(s), vim.log.levels.INFO, { title = "patchwork" })
end, {
  desc = "Show patchwork status (server, port, lockfile, clients)",
})

vim.api.nvim_create_user_command("PatchworkSend", function(opts)
  local main = lazy_main()
  local mode = vim.fn.mode()
  local sel = require("patchwork.selection")
  if opts.range == 2 and (mode ~= "v" and mode ~= "V" and mode ~= "\22") then
    -- :'<,'>PatchworkSend or :Range PatchworkSend
    local r = sel.get_range_selection(opts.line1, opts.line2)
    if r and r.filePath then
      main.send_at_mention(r.filePath, opts.line1 - 1, opts.line2 - 1, "PatchworkSend")
      return
    end
  end
  -- Visual / cursor: defer to the selection module (handles edge cases)
  sel.send_current_selection()
end, { range = true, desc = "Send current selection (or range) to claude as @mention" })
