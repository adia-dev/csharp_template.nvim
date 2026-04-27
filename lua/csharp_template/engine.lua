-- Lightweight snippet-style engine for C# template insertion.
--
-- Template nodes:
--   { type = "text",   value = "..." }
--   { type = "choice", id = N, choices = { "a", "b", ... } }  -- Tab-navigable, C-n/C-p cycles
--   { type = "input",  id = N, default = "..." }              -- Tab-navigable, free input
--
-- Key bindings active during a session (all buffer-local):
--   Tab       → next tabstop (exits session when past the last)
--   S-Tab     → previous tabstop
--   C-n       → cycle choice forward  (choice nodes only)
--   C-p       → cycle choice backward (choice nodes only)
--   Esc       → exit session immediately

local M = {}

local NS_MARKS = vim.api.nvim_create_namespace("csharp_template_marks")
local NS_HL = vim.api.nvim_create_namespace("csharp_template_hl")

vim.api.nvim_set_hl(0, "CsharpTemplateActive", { link = "Visual", default = true })
vim.api.nvim_set_hl(0, "CsharpTemplateInactive", { link = "Comment", default = true })

-- Active session state (one session at a time per Neovim instance).
local session = nil

-- ─── Helpers ────────────────────────────────────────────────────────────────

local function buf_set_text(bufnr, row, col, end_col, text)
	vim.api.nvim_buf_set_text(bufnr, row, col, row, end_col, { text })
end

local function mark_pos(bufnr, mark_id)
	local pos = vim.api.nvim_buf_get_extmark_by_id(bufnr, NS_MARKS, mark_id, {})
	return pos[1], pos[2] -- row (0-indexed), col
end

local function refresh_highlights(s)
	vim.api.nvim_buf_clear_namespace(s.bufnr, NS_HL, 0, -1)
	for i, stop in ipairs(s.stops) do
		if stop.width > 0 then
			local row, col = mark_pos(s.bufnr, stop.mark_id)
			local hl = (i == s.current) and "CsharpTemplateActive" or "CsharpTemplateInactive"
			vim.api.nvim_buf_add_highlight(s.bufnr, NS_HL, hl, row, col, col + stop.width)
		end
	end
end

local function jump_to_stop(s, idx)
	s.current = idx
	local stop = s.stops[idx]
	local row, col = mark_pos(s.bufnr, stop.mark_id)
	-- Move cursor to tabstop (1-indexed row for nvim_win_set_cursor).
	vim.api.nvim_win_set_cursor(0, { row + 1, col })
	refresh_highlights(s)
end

-- ─── Session teardown ───────────────────────────────────────────────────────

local function exit_session()
	if not session then
		return
	end
	local s = session
	session = nil

	vim.api.nvim_buf_clear_namespace(s.bufnr, NS_MARKS, 0, -1)
	vim.api.nvim_buf_clear_namespace(s.bufnr, NS_HL, 0, -1)

	-- Restore saved keymaps (or delete the buffer-local ones we set).
	local keys = { "n <Tab>", "n <S-Tab>", "n <C-n>", "n <C-p>", "n <Esc>" }
	for _, spec in ipairs(keys) do
		local mode, lhs = spec:match("^(%S+) (.+)$")
		pcall(vim.keymap.del, mode, lhs, { buffer = s.bufnr })
	end

	for _, saved in ipairs(s.saved_maps) do
		if saved.map and next(saved.map) ~= nil then
			vim.fn.mapset(saved.mode, false, saved.map)
		end
	end
end

-- ─── Key handlers ───────────────────────────────────────────────────────────

local function on_next()
	if not session then
		return
	end
	if session.current >= #session.stops then
		exit_session()
	else
		jump_to_stop(session, session.current + 1)
	end
end

local function on_prev()
	if not session then
		return
	end
	if session.current > 1 then
		jump_to_stop(session, session.current - 1)
	end
end

local function on_cycle(direction)
	if not session then
		return
	end
	local stop = session.stops[session.current]
	if #stop.choices <= 1 then
		return
	end

	local n = #stop.choices
	stop.choice_idx = ((stop.choice_idx - 1 + direction) % n) + 1
	local new_text = stop.choices[stop.choice_idx]

	local row, col = mark_pos(session.bufnr, stop.mark_id)
	buf_set_text(session.bufnr, row, col, col + stop.width, new_text)
	stop.width = #new_text
	refresh_highlights(session)
	-- Keep cursor at start of the stop.
	vim.api.nvim_win_set_cursor(0, { row + 1, col })
end

-- ─── Session setup ──────────────────────────────────────────────────────────

local function save_map(bufnr, mode, lhs)
	local existing = vim.fn.maparg(lhs, mode, false, true)
	if existing and existing.buffer == 1 then
		return existing
	end
	return nil
end

local function bind(bufnr, mode, lhs, fn)
	local saved = save_map(bufnr, mode, lhs)
	table.insert(session.saved_maps, { mode = mode, map = saved or {} })
	vim.keymap.set(mode, lhs, fn, { buffer = bufnr, nowait = true, silent = true })
end

-- ─── Build phase ────────────────────────────────────────────────────────────

-- Walk template nodes, produce the text lines and a list of tabstop descriptors
-- with byte offsets relative to the start of the inserted text.
local function build(nodes)
	local parts = {}
	local raw_stops = {} -- { id, byte_offset, width, choices, choice_idx }

	local byte_offset = 0

	for _, node in ipairs(nodes) do
		if node.type == "text" then
			table.insert(parts, node.value)
			byte_offset = byte_offset + #node.value
		elseif node.type == "choice" then
			local choices = node.choices
			local default = choices[1] or ""
			table.insert(raw_stops, {
				id = node.id,
				byte_offset = byte_offset,
				width = #default,
				choices = choices,
				choice_idx = 1,
			})
			table.insert(parts, default)
			byte_offset = byte_offset + #default
		elseif node.type == "input" then
			local default = node.default or ""
			table.insert(raw_stops, {
				id = node.id,
				byte_offset = byte_offset,
				width = #default,
				choices = { default },
				choice_idx = 1,
			})
			table.insert(parts, default)
			byte_offset = byte_offset + #default
		end
	end

	table.sort(raw_stops, function(a, b)
		return a.id < b.id
	end)

	local text = table.concat(parts)
	local lines = vim.split(text, "\n", { plain = true })
	return lines, raw_stops
end

-- Convert a byte offset in `text` (the joined string) to (row_offset, col)
-- relative to the start of the insertion.
local function offset_to_rowcol(text, offset)
	local row = 0
	local col = 0
	for i = 1, offset do
		if text:sub(i, i) == "\n" then
			row = row + 1
			col = 0
		else
			col = col + 1
		end
	end
	return row, col
end

-- ─── Public API ─────────────────────────────────────────────────────────────

-- Insert `nodes` at `insert_row` (0-indexed, lines are added AFTER this row).
-- Starts a tabstop session so the user can Tab/cycle through choices.
function M.insert(nodes, insert_row)
	if session then
		exit_session()
	end

	local bufnr = vim.api.nvim_get_current_buf()
	local lines, raw_stops = build(nodes)
	local joined = table.concat(lines, "\n")

	-- Insert the lines into the buffer.
	vim.api.nvim_buf_set_lines(bufnr, insert_row + 1, insert_row + 1, false, lines)

	if #raw_stops == 0 then
		return
	end

	-- Place extmarks for each tabstop.
	session = {
		bufnr = bufnr,
		stops = {},
		current = 1,
		saved_maps = {},
	}

	for _, rs in ipairs(raw_stops) do
		local row_off, col = offset_to_rowcol(joined, rs.byte_offset)
		local abs_row = insert_row + 1 + row_off
		local mark_id = vim.api.nvim_buf_set_extmark(bufnr, NS_MARKS, abs_row, col, {
			right_gravity = false,
		})
		table.insert(session.stops, {
			mark_id = mark_id,
			width = rs.width,
			choices = rs.choices,
			choice_idx = rs.choice_idx,
		})
	end

	-- Set buffer-local keymaps.
	bind(bufnr, "n", "<Tab>", on_next)
	bind(bufnr, "n", "<S-Tab>", on_prev)
	bind(bufnr, "n", "<C-n>", function()
		on_cycle(1)
	end)
	bind(bufnr, "n", "<C-p>", function()
		on_cycle(-1)
	end)
	bind(bufnr, "n", "<Esc>", exit_session)

	-- Jump to the first tabstop.
	jump_to_stop(session, 1)
end

return M
