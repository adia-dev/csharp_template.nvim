# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

A Neovim plugin (Lua) that automates C# boilerplate insertion. It inspects the nearest `.csproj` file to derive the correct namespace and generates file-scoped namespace declarations and `internal sealed class` stubs.

## Plugin architecture

Single public module at `lua/csharp_template/init.lua` that returns a table `M` with two public functions:

- `M.insert_namespace()` — walks up the directory tree to find the nearest `.csproj`, extracts `<RootNamespace>` (or falls back to the project file name), builds a dotted namespace from the relative path, and prepends `namespace <ns>;` to the current buffer if none exists.
- `M.insert_internal_sealed_class()` — inserts an `internal sealed class <FileName> { }` block after the namespace declaration (or at the top of the buffer), then positions the cursor inside the braces in insert mode.

All helper functions are module-local. The public API surface is intentionally minimal.

## Key design decisions

- Uses **file-scoped namespaces** (`namespace Foo.Bar;` with a semicolon) — the modern C# style introduced in C# 10.
- Classes default to `internal sealed` — the correct default for non-public types in .NET.
- Uses `vim.uv` (libuv) for file I/O instead of `io.*` to stay non-blocking and consistent with Neovim internals.
- `vim.fs.relpath` builds the sub-namespace from the file's directory relative to the project root.

## Installing / loading in Neovim

Typical lazy.nvim setup:

```lua
{
  dir = "~/Repositories/csharp_template",
  config = function()
    local ct = require("csharp_template")
    vim.keymap.set("n", "<leader>cn", ct.insert_namespace, { desc = "Insert C# namespace" })
    vim.keymap.set("n", "<leader>cc", ct.insert_internal_sealed_class, { desc = "Insert C# class" })
  end,
}
```

## Testing

There is no automated test suite yet. Testing is done by sourcing the plugin inside a live Neovim session pointed at a real C# project tree with `.csproj` files.

If plenary.nvim tests are added under `tests/`, run them with:

```sh
nvim --headless -c "PlenaryBustedDirectory tests/ { minimal_init = 'tests/minimal_init.lua' }" -c "qa"
```
