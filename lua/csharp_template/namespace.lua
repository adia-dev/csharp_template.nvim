local M = {}

local function read_file(path)
	local fd = vim.uv.fs_open(path, "r", 438)
	if not fd then
		return nil
	end

	local stat = vim.uv.fs_fstat(fd)
	if not stat then
		vim.uv.fs_close(fd)
		return nil
	end

	local data = vim.uv.fs_read(fd, stat.size, 0)
	vim.uv.fs_close(fd)
	return data
end

local function find_nearest_csproj(bufname)
	local dir = vim.fs.dirname(bufname)
	if not dir or dir == "" then
		return nil
	end

	while dir do
		local matches = vim.fn.globpath(dir, "*.csproj", false, true)
		if matches and #matches > 0 then
			table.sort(matches)
			return matches[1]
		end

		local parent = vim.fs.dirname(dir)
		if not parent or parent == dir then
			break
		end
		dir = parent
	end

	return nil
end

local function parse_root_namespace(csproj_path)
	local content = read_file(csproj_path)
	if not content then
		return nil
	end

	local root_ns = content:match("<RootNamespace>%s*([^<]-)%s*</RootNamespace>")
	if root_ns and root_ns ~= "" then
		return root_ns
	end

	return nil
end

local function default_root_namespace(csproj_path)
	local project_name = vim.fn.fnamemodify(csproj_path, ":t:r")
	if project_name == "" then
		return nil
	end
	return project_name
end

local function sanitize_part(part)
	return part:gsub("[^%w_]", "_")
end

-- Returns the namespace string for the given absolute file path, or nil.
function M.build(bufname)
	local csproj = find_nearest_csproj(bufname)
	if not csproj then
		return nil
	end

	local project_dir = vim.fs.dirname(csproj)
	local root_namespace = parse_root_namespace(csproj) or default_root_namespace(csproj)
	if not root_namespace or root_namespace == "" then
		return nil
	end

	local file_dir = vim.fs.dirname(bufname)
	local rel = vim.fs.relpath(project_dir, file_dir)

	if not rel or rel == "." then
		return root_namespace
	end

	rel = rel:gsub("\\", "/")

	local parts = vim.split(rel, "/", { plain = true, trimempty = true })
	local cleaned = {}

	for _, part in ipairs(parts) do
		local safe = sanitize_part(part)
		if safe ~= "" then
			table.insert(cleaned, safe)
		end
	end

	if #cleaned == 0 then
		return root_namespace
	end

	return root_namespace .. "." .. table.concat(cleaned, ".")
end

-- Returns true if the buffer already has a file-scoped namespace declaration.
function M.exists_in_buf(lines)
	for _, line in ipairs(lines) do
		if line:match("^%s*namespace%s+.+;%s*$") then
			return true
		end
	end
	return false
end

-- Returns the 1-indexed line number of the namespace declaration, or nil.
function M.find_line(lines)
	for i, line in ipairs(lines) do
		if line:match("^%s*namespace%s+.+;%s*$") then
			return i
		end
	end
	return nil
end

-- Inserts "namespace <ns>;" at the top of lines if not already present.
-- Returns new lines table and whether a change was made.
function M.insert_into_lines(lines, ns)
	if M.exists_in_buf(lines) then
		return lines, false
	end

	local ns_line = "namespace " .. ns .. ";"

	if #lines == 0 or (#lines == 1 and lines[1] == "") then
		return { ns_line, "" }, true
	end

	local result = { ns_line, "" }
	for _, line in ipairs(lines) do
		table.insert(result, line)
	end
	return result, true
end

return M
