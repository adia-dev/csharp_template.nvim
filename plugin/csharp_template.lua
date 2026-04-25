if vim.g.loaded_csharp_template then
	return
end
vim.g.loaded_csharp_template = true

local function get()
	return require("csharp_template")
end

vim.api.nvim_create_user_command("CsharpNamespace", function()
	get().insert_namespace()
end, { desc = "Insert file-scoped C# namespace" })
