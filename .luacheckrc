std = "luajit"
cache = true
codes = true

-- `vim` must be writable so that vim.bo / vim.wo / vim.b / vim.g / vim.env
-- assignments don't trip W122 (read-only field). Subfields are still scoped.
globals = {
  "vim",
}

ignore = {
  "212", -- unused argument
  "631", -- max line length
}
