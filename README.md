# csharp_template.nvim

A Neovim plugin for inserting C# boilerplate with an interactive tabstop system. Tab through visibility, modifier, and type-keyword fields; cycle options without leaving normal mode.

## Features

- Inserts class, record, struct, interface, and enum templates
- Auto-inserts the correct file-scoped namespace from the nearest `.csproj`
- Interactive tabstops: `<Tab>`/`<S-Tab>` to navigate, `<C-n>`/`<C-p>` to cycle choices
- User commands (`:CsharpClass`, etc.) and configurable keymaps
- Zero dependencies — pure Lua, no external plugins required

## Requirements

- Neovim 0.10+

## Installation

### lazy.nvim

```lua
{
  "yourusername/csharp_template.nvim",
  ft = "cs",
  config = function()
    require("csharp_template").setup()
  end,
}
```

### packer.nvim

```lua
use {
  "yourusername/csharp_template.nvim",
  ft = "cs",
  config = function()
    require("csharp_template").setup()
  end,
}
```

## Configuration

`setup()` is optional if you only want the user commands. Call it to enable default keymaps.

```lua
require("csharp_template").setup({
  -- Pass keymaps = false to disable all default keymaps.
  -- Or provide a custom list:
  keymaps = {
    { lhs = "<leader>cn", fn = "insert_namespace" },
    { lhs = "<leader>cc", fn = "insert_class" },
    { lhs = "<leader>cr", fn = "insert_record" },
    { lhs = "<leader>cs", fn = "insert_struct" },
    { lhs = "<leader>ci", fn = "insert_interface" },
    { lhs = "<leader>ce", fn = "insert_enum" },
  },
})
```

Keymaps are only bound for `filetype=cs` buffers.

## Usage

### User commands

| Command | Description |
|---------|-------------|
| `:CsharpNamespace` | Insert file-scoped namespace |
| `:CsharpClass` | Insert class template |
| `:CsharpRecord` | Insert record template |
| `:CsharpStruct` | Insert struct template |
| `:CsharpInterface` | Insert interface template |
| `:CsharpEnum` | Insert enum template |

### Default keymaps (cs filetype)

| Key | Action |
|-----|--------|
| `<leader>cn` | Insert namespace |
| `<leader>cc` | Insert class |
| `<leader>cr` | Insert record |
| `<leader>cs` | Insert struct |
| `<leader>ci` | Insert interface |
| `<leader>ce` | Insert enum |

### Interactive session

After inserting a template, a tabstop session starts. For example, `:CsharpClass` produces:

```
internal sealed class ClassName
{
}
```

The cursor lands on `internal` (highlighted). Navigate and cycle:

| Key | Action |
|-----|--------|
| `<Tab>` | Move to next tabstop (exits session after the last) |
| `<S-Tab>` | Move to previous tabstop |
| `<C-n>` | Cycle choice forward at the current stop |
| `<C-p>` | Cycle choice backward at the current stop |
| `<Esc>` | Exit session, keep current text |

#### Class tabstops

| Stop | Choices |
|------|---------|
| 1 — visibility | `internal` · `public` · `private` · `protected` |
| 2 — modifier | `sealed` · *(none)* · `abstract` · `static` |
| 3 — name | free input (defaults to `ClassName`) |

#### Record tabstops

| Stop | Choices |
|------|---------|
| 1 — visibility | `internal` · `public` · `private` · `protected` |
| 2 — modifier | `sealed` · *(none)* · `abstract` |
| 3 — name | free input (defaults to `RecordName`) |

#### Struct tabstops

| Stop | Choices |
|------|---------|
| 1 — visibility | `internal` · `public` · `private` · `protected` |
| 2 — modifier | `readonly` · *(none)* |
| 3 — name | free input (defaults to `StructName`) |

#### Interface / Enum tabstops

| Stop | Choices |
|------|---------|
| 1 — visibility | `internal` · `public` |
| 2 — name | free input |

### Namespace resolution

When inserting any template the plugin walks up the directory tree to find the nearest `.csproj`, reads the `<RootNamespace>` property (or falls back to the project file name), and prepends the relative subdirectory path as namespace segments. If no `.csproj` is found the namespace step is skipped silently.

Example: a file at `src/MyProject/Services/OrderService.cs` with a `.csproj` at `src/MyProject/` that has `<RootNamespace>MyProject</RootNamespace>` will get:

```csharp
namespace MyProject.Services;
```

## License

MIT
