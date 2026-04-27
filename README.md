# csharp_template.nvim



https://github.com/user-attachments/assets/86c8f8e6-a2bf-4728-bfd4-4617ff5b7a59



A Neovim plugin for inserting C# boilerplate with an interactive tabstop system. Tab through visibility, modifier, and type-keyword fields; cycle options without leaving normal mode.

## Features

- Inserts class, record, struct, interface, and enum templates
- Auto-inserts the correct file-scoped namespace from the nearest `.csproj`
- Interactive tabstops: `<Tab>`/`<S-Tab>` to navigate, `<C-n>`/`<C-p>` to cycle choices
- User commands (`:CsharpClass`, etc.) with no keymaps registered by default
- Zero dependencies — pure Lua, no external plugins required

## Requirements

- Neovim 0.10+

## Installation

### lazy.nvim

```lua
{
  "adia-dev/csharp_template.nvim",
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

### packer.nvim

```lua
use { "adia-dev/csharp_template.nvim" }
```

## Configuration

No keymaps are registered by default — `setup()` is a no-op unless you explicitly pass a `keymaps` list. The recommended approach is to let your plugin manager handle keymaps (as shown above). If you prefer `setup()`:

```lua
require("csharp_template").setup({
  keymaps = {
    { lhs = "<leader>cn", fn = "insert_namespace", desc = "C#: insert namespace" },
    { lhs = "<leader>cc", fn = "insert_class",     desc = "C#: insert class" },
    { lhs = "<leader>cr", fn = "insert_record",    desc = "C#: insert record" },
    { lhs = "<leader>cs", fn = "insert_struct",    desc = "C#: insert struct" },
    { lhs = "<leader>ci", fn = "insert_interface", desc = "C#: insert interface" },
    { lhs = "<leader>ce", fn = "insert_enum",      desc = "C#: insert enum" },
  },
})
```

Keymaps provided via `setup()` are bound buffer-locally on `FileType=cs`.

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

### Namespace correction

Running `:CsharpNamespace` (or its keymap) on a buffer that already has a namespace declaration compares it against the expected value derived from the `.csproj`:

- **Correct** — notifies "Namespace is correct: …" and does nothing.
- **Mismatch** — prompts `Fix namespace? Old.Name → New.Name`. Confirm with `Yes` to replace the declaration in place; `No` leaves the buffer untouched.

This is useful after moving a file to a different directory.

## License

MIT
