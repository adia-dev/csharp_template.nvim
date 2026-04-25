if vim.g.loaded_csharp_template then
	return
end
vim.g.loaded_csharp_template = true

local function get()
	return require("csharp_template")
end

local cmds = {
	{ name = "CsharpNamespace", fn = "insert_namespace", desc = "Insert file-scoped C# namespace" },
	{ name = "CsharpClass",     fn = "insert_class",     desc = "Insert C# class template" },
	{ name = "CsharpRecord",    fn = "insert_record",    desc = "Insert C# record template" },
	{ name = "CsharpStruct",    fn = "insert_struct",    desc = "Insert C# struct template" },
	{ name = "CsharpInterface", fn = "insert_interface", desc = "Insert C# interface template" },
	{ name = "CsharpEnum",      fn = "insert_enum",      desc = "Insert C# enum template" },
}

for _, cmd in ipairs(cmds) do
	local fn = cmd.fn
	vim.api.nvim_create_user_command(cmd.name, function()
		get()[fn]()
	end, { desc = cmd.desc })
end
