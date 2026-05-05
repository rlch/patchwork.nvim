-- Smoke test: load every Lua module and exercise the entry point.
-- Run via:  nvim --headless -u NONE --cmd "set rtp+=$PWD" -l scripts/smoke_test.lua

local fail = false

local function check(file)
  local fn, err = loadfile(file)
  if not fn then
    io.stderr:write("compile failed: " .. file .. ": " .. tostring(err) .. "\n")
    fail = true
  end
end

for _, f in ipairs(vim.fn.glob("lua/**/*.lua", false, true)) do
  check(f)
end
for _, f in ipairs(vim.fn.glob("plugin/*.lua", false, true)) do
  check(f)
end

if fail then
  os.exit(1)
end

local ok, mod = pcall(require, "patchwork")
if not ok then
  io.stderr:write("require('patchwork') failed: " .. tostring(mod) .. "\n")
  os.exit(1)
end

local setup_ok, setup_err = pcall(mod.setup, { auto_start = false })
if not setup_ok then
  io.stderr:write("patchwork.setup failed: " .. tostring(setup_err) .. "\n")
  os.exit(1)
end

print("smoke test ok")
