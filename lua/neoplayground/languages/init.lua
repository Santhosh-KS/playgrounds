-- lua/neoplayground/languages/init.lua
local M = {}

-- Table to store language handlers
local languages = {}

-- Function to register a language
function M.register_language(lang_name, lang_handler)
	languages[lang_name] = lang_handler
end

-- Function to get a language handler
function M.get_language(lang_name)
	return languages[lang_name]
end

-- Load and register all language handlers
local function load_languages()
	languages.lua = require("neoplayground.languages.lua")
	languages.python = require("neoplayground.languages.python")
	languages.go = require("neoplayground.languages.go")
	languages.swift = require("neoplayground.languages.swift")
	languages.cpp = require("neoplayground.languages.cpp")
	languages.c = require("neoplayground.languages.c")
	languages.javascript = require("neoplayground.languages.javascript")
	languages.elixir = require("neoplayground.languages.elixir")
end

-- Initialize languages on module load
load_languages()

return M
