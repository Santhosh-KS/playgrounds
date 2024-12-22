-- lua/neoplayground/ui/window.lua
local M = {}

M.state = {
	output_buf = nil,
	output_win = nil,
	original_win = nil,
}

function M.create_output_window()
	if M.state.output_win and vim.api.nvim_win_is_valid(M.state.output_win) then
		return M.state.output_win
	end

	M.state.original_win = vim.api.nvim_get_current_win()

	vim.cmd("vsplit")
	M.state.output_win = vim.api.nvim_get_current_win()
	vim.cmd("wincmd L")

	if not M.state.output_buf or not vim.api.nvim_buf_is_valid(M.state.output_buf) then
		M.state.output_buf = vim.api.nvim_create_buf(false, true)

		local buf_options = {
			buftype = "nofile",
			bufhidden = "hide",
			swapfile = false,
			modifiable = true,
			filetype = "playground-output",
		}

		for option, value in pairs(buf_options) do
			vim.api.nvim_buf_set_option(M.state.output_buf, option, value)
		end
	end

	vim.api.nvim_win_set_buf(M.state.output_win, M.state.output_buf)

	local win_options = {
		wrap = false,
		cursorline = true,
		number = true,
		relativenumber = false,
		signcolumn = "no",
	}

	for option, value in pairs(win_options) do
		vim.api.nvim_win_set_option(M.state.output_win, option, value)
	end

	vim.api.nvim_set_current_win(M.state.original_win)
	return M.state.output_win
end

function M.update_content(content_lines)
	if not M.state.output_buf or not vim.api.nvim_buf_is_valid(M.state.output_buf) then
		return
	end

	-- Make buffer modifiable
	vim.api.nvim_buf_set_option(M.state.output_buf, "modifiable", true)

	-- Ensure we have a table of lines
	local lines = {}
	if type(content_lines) == "table" then
		for i = 1, #content_lines do
			local line = content_lines[i]
			if line then
				-- Convert to string and ensure no newlines
				lines[i] = tostring(line):gsub("\n", " ")
			else
				lines[i] = ""
			end
		end
	else
		lines = { tostring(content_lines):gsub("\n", " ") }
	end

	-- Update buffer content
	pcall(vim.api.nvim_buf_set_lines, M.state.output_buf, 0, -1, false, lines)

	-- Make buffer non-modifiable
	vim.api.nvim_buf_set_option(M.state.output_buf, "modifiable", false)
end

function M.cleanup()
	if M.state.output_buf and vim.api.nvim_buf_is_valid(M.state.output_buf) then
		vim.api.nvim_buf_delete(M.state.output_buf, { force = true })
	end

	M.state.output_buf = nil
	M.state.output_win = nil
	M.state.original_win = nil
end

function M.handle_resize()
	-- Add resize handling if needed
end

return M
