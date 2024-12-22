-- lua/neoplayground/languages/init.lua
local M = {}

-- Table to store language handlers
local language_handlers = {}

-- Function to register a language
function M.register_language(lang_name, lang_handler)
	language_handlers[lang_name] = lang_handler
end

-- Function to get a language handler
function M.get_language(lang_name)
	return language_handlers[lang_name]
end

-- Load and register all language handlers
local function load_languages()
	-- Load Go language handler
	local go = require("neoplayground.languages.go")
	M.register_language("go", go)

	-- Later we can add more languages here
	-- local python = require('neoplayground.languages.python')
	-- M.register_language('python', python)
end

-- Initialize languages
load_languages()

return M -- lua/neoplayground/languages/init.lua
