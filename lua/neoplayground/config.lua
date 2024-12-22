-- lua/neoplayground/config.lua
local M = {}

-- Default configuration
M.defaults = {
	-- General settings
	auto_refresh = true,
	split_width = 0.5,
	split_position = "right", -- 'right' or 'left'
	show_line_numbers = true,

	-- Language specific settings
	languages = {
		javascript = {
			enabled = true,
			command_name = "JavaScriptPlaygroundStart",
			file_pattern = "*.js",
			show_return_value = true,
			executor = {
				command = "node",
				timeout = 5000,
			},
		},
		elixir = {
			enabled = true,
			command_name = "ElixirPlaygroundStart",
			file_pattern = "*.ex",
			show_return_value = true,
			executor = {
				command = "elixir",
				timeout = 5000,
			},
		},
		lua = {
			enabled = true,
			command_name = "LuaPlaygroundStart",
			file_pattern = "*.lua",
			show_return_value = true,
			executor = {
				command = "/usr/bin/lua",
				timeout = 5000, -- milliseconds
			},
		},
		python = {
			enabled = true,
			command_name = "PythonPlaygroundStart",
			file_pattern = "*.py",
			show_return_value = true,
			executor = {
				command = "python3",
				timeout = 5000,
				virtual_env = nil, -- Path to virtual env if needed
			},
		},
		go = {
			enabled = true,
			command_name = "GoPlaygroundStart",
			file_pattern = "*.go",
			show_return_value = true,
			executor = {
				command = "go",
				timeout = 5000,
				build_flags = {}, -- Additional build flags
			},
		},
		cpp = {
			enabled = true,
			command_name = "CppPlaygroundStart",
			file_pattern = "*.cpp",
			show_return_value = true,
			executor = {
				command = "g++",
				timeout = 5000,
				compile_flags = { "-std=c++17" }, -- Default compile flags
			},
		},
		c = {
			enabled = true,
			command_name = "CPlaygroundStart",
			file_pattern = "*.c",
			show_return_value = true,
			executor = {
				command = "gcc",
				timeout = 5000,
				compile_flags = {}, -- Default compile flags
			},
		},
		swift = {
			enabled = true,
			command_name = "SwiftPlaygroundStart",
			file_pattern = "*.swift",
			show_return_value = true,
			executor = {
				command = "swift",
				timeout = 5000,
			},
		},
	},

	-- UI settings
	ui = {
		border = "rounded", -- 'none', 'single', 'double', 'rounded'
		highlight = {
			output = "Normal",
			error = "ErrorMsg",
			warning = "WarningMsg",
		},
	},
}

-- Current configuration (will be merged with user config)
M.current = vim.deepcopy(M.defaults)

-- Setup function
function M.setup(opts)
	if opts then
		-- Deep merge user config with defaults
		M.current = vim.tbl_deep_extend("force", M.defaults, opts)
	end

	-- Validate configuration
	M.validate()
end

-- Get specific language configuration
function M.get_language_config(lang)
	return M.current.languages[lang]
end

-- Get all language configurations
function M.get_languages()
	return M.current.languages
end

-- Get UI configuration
function M.get_ui_config()
	return M.current.ui
end

-- Get general settings
function M.get_general()
	local general = vim.deepcopy(M.current)
	general.languages = nil
	general.ui = nil
	return general
end

-- Validate configuration
function M.validate()
	-- Check if required executables exist
	for lang, config in pairs(M.current.languages) do
		if config.enabled then
			local cmd = config.executor.command
			local exists = vim.fn.executable(cmd) == 1

			if not exists then
				vim.notify(
					string.format("Playground: %s executable '%s' not found. Disabling %s playground.", lang, cmd, lang),
					vim.log.levels.WARN
				)
				config.enabled = false
			end
		end
	end

	-- Validate split position
	if M.current.split_position ~= "right" and M.current.split_position ~= "left" then
		vim.notify("Invalid split_position value. Using 'right'.", vim.log.levels.WARN)
		M.current.split_position = "right"
	end

	-- Validate split width
	if type(M.current.split_width) ~= "number" or M.current.split_width <= 0 or M.current.split_width >= 1 then
		vim.notify("Invalid split_width value. Using 0.5.", vim.log.levels.WARN)
		M.current.split_width = 0.5
	end
end

return M
