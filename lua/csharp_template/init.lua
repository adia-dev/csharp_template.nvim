local ns_mod = require("csharp_template.namespace")
local engine = require("csharp_template.engine")
local templates = require("csharp_template.templates")

local M = {}

-- setup(opts) — optional, only needed if you want plugin-managed keymaps.
--
-- opts.keymaps: list of { lhs, fn, desc? } entries — no default list.
--   fn is the name of a public method on this module (e.g. "insert_class").
--   Keymaps are bound buffer-locally on FileType=cs.
--   Omitting opts.keymaps (or calling setup with no args) registers nothing.
M.setup = function(opts)
	opts = opts or {}

	if not opts.keymaps or #opts.keymaps == 0 then
		return
	end

	vim.api.nvim_create_autocmd("FileType", {
		pattern = "cs",
		group = vim.api.nvim_create_augroup("csharp_template_keymaps", { clear = true }),
		callback = function(ev)
			for _, km in ipairs(opts.keymaps) do
				local fn = M[km.fn]
				if fn then
					vim.keymap.set("n", km.lhs, fn, {
						buffer = ev.buf,
						silent = true,
						desc = km.desc or km.fn,
					})
				end
			end
		end,
	})
end

-- ─── Namespace ───────────────────────────────────────────────────────────────

function M.insert_namespace()
	local bufnr = vim.api.nvim_get_current_buf()
	local bufname = vim.api.nvim_buf_get_name(bufnr)

	if bufname == "" then
		vim.notify("Current buffer has no file name", vim.log.levels.WARN)
		return
	end

	local expected = ns_mod.build(bufname)
	if not expected then
		vim.notify("Could not determine C# namespace from nearest .csproj", vim.log.levels.WARN)
		return
	end

	local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
	local current = ns_mod.get_from_buf(lines)

	if current then
		if current == expected then
			vim.notify("Namespace is correct: " .. expected, vim.log.levels.INFO)
			return
		end

		vim.ui.select({ "Yes", "No" }, {
			prompt = string.format("Fix namespace? %s → %s", current, expected),
		}, function(choice)
			if choice ~= "Yes" then
				return
			end
			local ns_line_idx = ns_mod.find_line(lines)
			vim.api.nvim_buf_set_lines(bufnr, ns_line_idx - 1, ns_line_idx, false, {
				"namespace " .. expected .. ";",
			})
			vim.notify("Namespace updated to: " .. expected, vim.log.levels.INFO)
		end)
		return
	end

	local new_lines, changed = ns_mod.insert_into_lines(lines, expected)
	if not changed then
		vim.notify("Namespace already exists", vim.log.levels.INFO)
		return
	end

	vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, new_lines)
end

-- ─── Template insertion helpers ──────────────────────────────────────────────

-- Ensures the namespace is present, then returns the 0-indexed row after
-- which the template should be inserted (the namespace line, or -1 for top).
local function prepare_buffer(bufnr, bufname)
	local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

	if bufname ~= "" then
		local ns = ns_mod.build(bufname)
		if ns then
			local new_lines, changed = ns_mod.insert_into_lines(lines, ns)
			if changed then
				vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, new_lines)
				lines = new_lines
			end
		end
	end

	-- Find the namespace line to insert after it; fall back to last line.
	local ns_line = ns_mod.find_line(lines)
	if ns_line then
		-- ns_line is 1-indexed. Skip blank lines immediately after the namespace,
		-- then insert before the first non-blank line that follows.
		local next_line = ns_line + 1
		while next_line <= #lines and (lines[next_line] or "") == "" do
			next_line = next_line + 1
		end
		-- next_line is the 1-indexed first non-blank after ns (or #lines+1).
		-- We insert AFTER the last blank, which is row (next_line - 1) in 0-indexed.
		-- engine.insert adds lines after insert_row, so pass next_line - 2.
		return next_line - 2
	end

	return #lines - 1 -- append at end (0-indexed last line)
end

-- Generic template runner.
local function insert_template(tpl_nodes)
	local bufnr = vim.api.nvim_get_current_buf()
	local bufname = vim.api.nvim_buf_get_name(bufnr)
	local insert_row = prepare_buffer(bufnr, bufname)
	engine.insert(tpl_nodes, insert_row)
end

-- ─── Public template functions ───────────────────────────────────────────────

function M.insert_class()     insert_template(templates.class)     end
function M.insert_record()    insert_template(templates.record)    end
function M.insert_struct()    insert_template(templates.struct)    end
function M.insert_interface() insert_template(templates.interface) end
function M.insert_enum()      insert_template(templates.enum)      end

-- Legacy: kept for backward compatibility.
function M.insert_internal_sealed_class()
	M.insert_class()
end

return M
