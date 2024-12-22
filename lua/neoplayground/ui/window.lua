-- lua/neoplayground/ui/window.lua
local M = {}

-- Window state
M.state = {
	output_buf = nil,
	output_win = nil,
	original_win = nil,
}

function M.create_output_window()
	-- If window exists and is valid, return it
	if M.state.output_win and vim.api.nvim_win_is_valid(M.state.output_win) then
		return M.state.output_win
	end

	-- Store current window
	M.state.original_win = vim.api.nvim_get_current_win()

	-- Create split
	vim.cmd("vsplit")
	M.state.output_win = vim.api.nvim_get_current_win()
	vim.cmd("wincmd L")

	-- Create or get output buffer
	if not M.state.output_buf or not vim.api.nvim_buf_is_valid(M.state.output_buf) then
		M.state.output_buf = vim.api.nvim_create_buf(false, true)

		-- Set buffer options
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

	-- Set the buffer in the output window
	vim.api.nvim_win_set_buf(M.state.output_win, M.state.output_buf)

	-- Set window options
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

	-- Return to original window
	vim.api.nvim_set_current_win(M.state.original_win)

	return M.state.output_win
end

function M.update_content(content_lines)
	if not M.state.output_buf or not vim.api.nvim_buf_is_valid(M.state.output_buf) then
		return
	end

	-- Ensure content_lines is a table
	if type(content_lines) ~= "table" then
		content_lines = { tostring(content_lines) }
	end

	-- Filter and convert lines
	local filtered_lines = {}
	for _, line in ipairs(content_lines) do
		table.insert(filtered_lines, tostring(line))
	end

	-- Update buffer content
	vim.api.nvim_buf_set_option(M.state.output_buf, "modifiable", true)
	vim.api.nvim_buf_set_lines(M.state.output_buf, 0, -1, false, filtered_lines)
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

return M
