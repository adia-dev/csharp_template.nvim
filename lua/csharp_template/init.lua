local ns_mod = require("csharp_template.namespace")

local M = {}

M.setup = function(_opts) end

function M.insert_namespace()
	local bufnr = vim.api.nvim_get_current_buf()
	local bufname = vim.api.nvim_buf_get_name(bufnr)

	if bufname == "" then
		vim.notify("Current buffer has no file name", vim.log.levels.WARN)
		return
	end

	local namespace = ns_mod.build(bufname)
	if not namespace then
		vim.notify("Could not determine C# namespace from nearest .csproj", vim.log.levels.WARN)
		return
	end

	local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
	local new_lines, changed = ns_mod.insert_into_lines(lines, namespace)

	if not changed then
		vim.notify("Namespace already exists", vim.log.levels.INFO)
		return
	end

	vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, new_lines)
end

-- Legacy: kept for backward compatibility.
function M.insert_internal_sealed_class()
	local bufnr = vim.api.nvim_get_current_buf()
	local bufname = vim.api.nvim_buf_get_name(bufnr)

	if bufname == "" then
		vim.notify("Current buffer has no file name", vim.log.levels.WARN)
		return
	end

	local type_name = vim.fn.fnamemodify(bufname, ":t:r")
	if type_name == "" then
		vim.notify("Could not determine class name from file name", vim.log.levels.WARN)
		return
	end

	local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
	local class_lines = {
		"internal sealed class " .. type_name,
		"{",
		"}",
	}

	local final_lines
	if #lines == 0 or (#lines == 1 and lines[1] == "") then
		final_lines = class_lines
	else
		-- Insert after namespace line if present, otherwise append.
		local result = {}
		local inserted = false
		for i, line in ipairs(lines) do
			table.insert(result, line)
			if not inserted and line:match("^%s*namespace%s+.+;%s*$") then
				if i < #lines and lines[i + 1] ~= "" then
					table.insert(result, "")
				end
				for _, cl in ipairs(class_lines) do
					table.insert(result, cl)
				end
				inserted = true
			end
		end
		if not inserted then
			if #result > 0 and result[#result] ~= "" then
				table.insert(result, "")
			end
			for _, cl in ipairs(class_lines) do
				table.insert(result, cl)
			end
		end
		final_lines = result
	end

	vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, final_lines)

	for i, line in ipairs(final_lines) do
		if line == "{" then
			vim.api.nvim_win_set_cursor(0, { i, 0 })
			vim.cmd("normal! o")
			return
		end
	end
end

return M
