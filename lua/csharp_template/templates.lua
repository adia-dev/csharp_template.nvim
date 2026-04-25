-- Template node definitions for each C# type.
--
-- Tabstop IDs determine Tab order (ascending).
-- "choice" nodes cycle with C-n/C-p; "input" nodes accept free text.

local M = {}

M.class = {
	{ type = "choice", id = 1, choices = { "internal", "public", "private", "protected" } },
	{ type = "text",   value = " " },
	{ type = "choice", id = 2, choices = { "sealed", "", "abstract", "static" } },
	{ type = "text",   value = " class " },
	{ type = "input",  id = 3, default = "ClassName" },
	{ type = "text",   value = "\n{\n}" },
}

M.record = {
	{ type = "choice", id = 1, choices = { "internal", "public", "private", "protected" } },
	{ type = "text",   value = " " },
	{ type = "choice", id = 2, choices = { "sealed", "", "abstract" } },
	{ type = "text",   value = " record " },
	{ type = "input",  id = 3, default = "RecordName" },
	{ type = "text",   value = "\n{\n}" },
}

M.struct = {
	{ type = "choice", id = 1, choices = { "internal", "public", "private", "protected" } },
	{ type = "text",   value = " " },
	{ type = "choice", id = 2, choices = { "readonly", "" } },
	{ type = "text",   value = " struct " },
	{ type = "input",  id = 3, default = "StructName" },
	{ type = "text",   value = "\n{\n}" },
}

M.interface = {
	{ type = "choice", id = 1, choices = { "internal", "public" } },
	{ type = "text",   value = " interface " },
	{ type = "input",  id = 2, default = "IInterfaceName" },
	{ type = "text",   value = "\n{\n}" },
}

M.enum = {
	{ type = "choice", id = 1, choices = { "internal", "public" } },
	{ type = "text",   value = " enum " },
	{ type = "input",  id = 2, default = "EnumName" },
	{ type = "text",   value = "\n{\n}" },
}

return M
