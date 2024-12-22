-- lua/neoplayground/ui/init.lua
local M = {}
local window = require("neoplayground.ui.window")

function M.setup()
	-- Setup function can be empty for now
end

function M.create_output_window()
	return window.create_output_window()
end

function M.update_output_window(content_lines)
	window.update_content(content_lines)
end

function M.cleanup()
	window.cleanup()
end

return M
