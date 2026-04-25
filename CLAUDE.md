# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

A Neovim plugin (Lua) that inserts C# boilerplate — namespace, class, record, struct, interface, enum — with an interactive tabstop/choice system so the user can Tab through visibility, modifier, and type-keyword fields and cycle options with `<C-n>`/`<C-p>`.

## Module layout

```
lua/csharp_template/
  init.lua        Public API + setup(opts) with default keymaps
  namespace.lua   .csproj discovery, root-namespace extraction, buffer insertion
  engine.lua      Tabstop session: extmark tracking, key handlers, highlights
  templates.lua   Node-list definitions for each C# type
plugin/
  csharp_template.lua   User commands (:CsharpClass, :CsharpRecord, …)
```

## Key design decisions

**engine.lua — how the session works**
- Template nodes are `{type="text"|"choice"|"input", …}`. A "choice" node has a `choices` list; an "input" node has a free-text `default`.
- `engine.insert(nodes, insert_row)` builds the text, inserts it at `insert_row+1` (0-indexed), then places one extmark per tabstop (`right_gravity=false`) so marks survive edits to earlier lines.
- Buffer-local keymaps for Tab/S-Tab/C-n/C-p/Esc are installed on session start and removed (with original map restored) on session end.
- Highlights: `CsharpTemplateActive` (links to `Visual`) for the current stop, `CsharpTemplateInactive` (links to `Comment`) for the rest.

**init.lua — prepare_buffer**
- Before inserting a template, `prepare_buffer` auto-inserts the file-scoped namespace (if a `.csproj` is reachable and none exists yet), then computes the 0-indexed insertion row (after the namespace line, skipping any blank lines that already follow it).

**Templates use file-scoped namespace style** (`namespace Foo.Bar;`) and default to `internal` visibility — matching modern C# conventions.

## Installing in Neovim (lazy.nvim)

No keymaps are registered by default — `setup()` only registers keymaps when `opts.keymaps` is explicitly provided. The idiomatic lazy.nvim approach (used in this repo's own config) is to skip `setup()` entirely and let lazy handle loading via its `keys` spec:

```lua
{
  dir = "~/Repositories/csharp_template",
  lazy = true,
  keys = {
    { "<leader>cn", function() require("csharp_template").insert_namespace() end, desc = "C#: insert namespace" },
    { "<leader>cc", function() require("csharp_template").insert_class() end,     desc = "C#: insert class" },
    { "<leader>cr", function() require("csharp_template").insert_record() end,    desc = "C#: insert record" },
    { "<leader>cs", function() require("csharp_template").insert_struct() end,    desc = "C#: insert struct" },
    { "<leader>ci", function() require("csharp_template").insert_interface() end, desc = "C#: insert interface" },
    { "<leader>ce", function() require("csharp_template").insert_enum() end,      desc = "C#: insert enum" },
  },
}
```

User commands are always available: `:CsharpClass`, `:CsharpRecord`, `:CsharpStruct`, `:CsharpInterface`, `:CsharpEnum`, `:CsharpNamespace`.

## Session key bindings (active while inserting a template)

| Key | Action |
|-----|--------|
| `<Tab>` | Next tabstop (exits session after last) |
| `<S-Tab>` | Previous tabstop |
| `<C-n>` | Cycle choice forward at current stop |
| `<C-p>` | Cycle choice backward at current stop |
| `<Esc>` | Exit session immediately |

## Adding a new template

1. Add a node list to `templates.lua` (follow the same `id`-ordered pattern).
2. Add `M.insert_<name>()` in `init.lua` calling `insert_template(templates.<name>)`.
3. Add a command entry in `plugin/csharp_template.lua`.
4. Optionally add a default keymap entry in the `setup()` defaults table in `init.lua`.

## Testing

No automated test suite. Test by loading the plugin in a live Neovim session pointed at a directory that has a `.csproj` file.

If plenary.nvim tests are added under `tests/`:

```sh
nvim --headless -c "PlenaryBustedDirectory tests/ { minimal_init = 'tests/minimal_init.lua' }" -c "qa"
```
