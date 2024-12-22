-- plugin/neoplayground.lua
if vim.g.loaded_neoplayground then
	return
end
vim.g.loaded_neoplayground = 1

-- Defer plugin initialization
vim.api.nvim_create_autocmd("VimEnter", {
	callback = function()
		local playground = require("neoplayground")
		playground.setup()
	end,
})

-- Create basic commands
vim.api.nvim_create_user_command("PlaygroundToggle", function()
	local playground = require("neoplayground")
	if vim.b.is_playground then
		playground.stop_playground()
	else
		local filetype = vim.bo.filetype
		playground.start_playground(filetype)
	end
end, {})
