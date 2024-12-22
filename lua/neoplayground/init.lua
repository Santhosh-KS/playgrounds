-- lua/neoplayground/init.lua
local M = {}

-- Plugin state
M.state = {
	initialized = false,
	current_lang = nil,
}

-- Store module references
local config = nil
local ui = nil
local languages = nil

function M.setup(opts)
	if M.state.initialized then
		return
	end

	-- Load modules
	config = require("neoplayground.config")
	ui = require("neoplayground.ui")
	languages = require("neoplayground.languages")

	-- Initialize
	config.setup(opts)
	ui.setup()

	-- Create autocommand group
	local augroup = vim.api.nvim_create_augroup("NeoPlayground", { clear = true })

	-- Create commands and autocommands for each language
	for lang_name, lang_config in pairs(config.get_languages()) do
		if lang_config.enabled then
			local lang = languages.get_language(lang_name)
			if lang then
				-- Create command
				vim.api.nvim_create_user_command(lang.command_name, function()
					M.start_playground(lang_name)
				end, {
					desc = string.format("Start %s playground", lang_name),
				})

				-- Create autocommand for file save
				vim.api.nvim_create_autocmd("BufWritePost", {
					group = augroup,
					pattern = lang.file_pattern,
					callback = function()
						local current_buf = vim.api.nvim_get_current_buf()
						if vim.b[current_buf].is_playground then
							M.update_output(current_buf, lang_name)
						end
					end,
				})
			end
		end
	end

	M.state.initialized = true
end

--
-- Start playground for a specific language
function M.start_playground(lang_name)
	if not languages then
		return
	end

	local lang = languages.get_language(lang_name)
	if not lang then
		vim.notify(string.format("Language '%s' not supported", lang_name), vim.log.levels.ERROR)
		return
	end

	-- Set buffer local variables
	vim.b.is_playground = true
	vim.b.playground_lang = lang_name
	M.state.current_lang = lang_name

	-- Create output window
	ui.create_output_window()

	-- Initial update
	M.update_output(vim.api.nvim_get_current_buf(), lang_name)
end

-- Update output for the current buffer
function M.update_output(buf, lang_name)
	if not languages or not ui then
		return
	end

	-- Get language handler
	local lang = languages.get_language(lang_name)
	if not lang then
		vim.notify(string.format("Language '%s' not found", lang_name), vim.log.levels.ERROR)
		return
	end

	-- Get buffer content
	local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
	local content = table.concat(lines, "\n")

	-- Execute code
	local success, output_lines = pcall(lang.execute, lang, content, #lines)

	if not success then
		output_lines = {
			string.format("Error executing %s code:", lang_name),
			output_lines,
		}
	end

	-- Update output window
	ui.update_output_window(output_lines)
end

-- Stop playground
function M.stop_playground()
	vim.b.is_playground = false
	vim.b.playground_lang = nil
	M.state.current_lang = nil
	if ui then
		ui.cleanup()
	end
end

-- Handle window resize
function M.handle_resize()
	if ui and M.state.current_lang then
		ui.handle_resize()
	end
end

return M
