# patchwork.nvim

[![CI](https://github.com/rlch/patchwork.nvim/actions/workflows/ci.yml/badge.svg)](https://github.com/rlch/patchwork.nvim/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](./LICENSE)
[![Neovim](https://img.shields.io/badge/Neovim-%3E%3D%200.10-57A143?logo=neovim&logoColor=white)](https://neovim.io/)

A Neovim plugin that bridges AI coding agents to your editor and renders proposed changes as a VS Code-style **inline diff** — accept or reject with one keystroke.

> **Status:** early / WIP. Currently speaks Claude Code's IDE protocol; designed to extend to other agents.

## What it does

- Runs a **passive WebSocket + MCP server** in your Neovim instance and writes a lockfile so an AI agent (Claude Code today) can discover and connect.
- When the agent proposes an edit, opens it in a **unified inline diff** view with `+`/`−` lines, character-level highlights, dual line-number gutter, and hunk navigation.
- Built for a **terminal multiplexer** workflow — the agent runs in one tmux/zellij/wezterm pane, nvim runs in another, the plugin glues them together with no terminal embedding.

## Requirements

- Neovim ≥ 0.10
- A connected agent (Claude Code) running in the same machine

## Installation

With [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
  "rlch/patchwork.nvim",
  event = "VeryLazy",
  cmd = { "PatchworkStart", "PatchworkStop", "PatchworkStatus", "PatchworkSend" },
  opts = {
    diff_opts = {
      layout = "inline", -- "inline" | "vertical" | "horizontal"
    },
  },
}
```

The plugin auto-starts the server on load (configurable via `auto_start = false`). When Claude Code launches in another pane, it picks up the lockfile and connects.

## Commands

| Command | Description |
|---|---|
| `:PatchworkStart` | Start the WebSocket server and write the lockfile. |
| `:PatchworkStop` | Stop the server and remove the lockfile. |
| `:PatchworkStatus` | Show server, port, lockfile, connected clients. |
| `:PatchworkSend` | Send the current selection (or `:'<,'>` range) to the agent as an `@mention`. |

## Diff view keymaps (inline mode)

Active inside the inline diff buffer:

| Key | Action |
|---|---|
| `ga` | Accept the diff (writes the proposal). |
| `gr` / `q` | Reject the diff. |
| `]c` / `[c` | Jump to next / previous hunk. |

Side-by-side mode uses `:w` to accept and `:q` / `:bd` to reject.

## Configuration

Defaults:

```lua
{
  auto_start = true,
  log_level = "info",
  port_range = { min = 10000, max = 65535 },

  track_selection = true,
  visual_demotion_delay_ms = 50,

  connection_wait_delay = 600,
  connection_timeout = 10000,
  queue_timeout = 5000,

  diff_opts = {
    layout = "inline",        -- "inline" | "vertical" | "horizontal"
    open_in_new_tab = false,
    keep_terminal_focus = false,
    hide_terminal_in_new_tab = false,
    on_new_file_reject = "keep_empty",
  },
}
```

## Acknowledgments

- **[`coder/claudecode.nvim`](https://github.com/coder/claudecode.nvim)** — the WebSocket and MCP transport stack is forked from this project (MIT). See [`LICENSE`](./LICENSE) for full attribution.
- **[`Cannon07/code-preview.nvim`](https://github.com/Cannon07/code-preview.nvim)** — the inline-diff layout and dual-column statuscolumn idea are inspired by this plugin (MIT).
- **[`esmuellert/codediff.nvim`](https://github.com/esmuellert/codediff.nvim)** — VS Code-style two-tier highlighting design reference.

## License

MIT — see [`LICENSE`](./LICENSE).
