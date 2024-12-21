-- lua/neoplayground/languages/init.lua
local M = {}

M.lua = require('neoplayground.languages.lua')
M.python = require('neoplayground.languages.python')
M.go = require('neoplayground.languages.go')
M.swift = require('neoplayground.languages.swift')
M.cpp = require('neoplayground.languages.cpp')
M.c = require('neoplayground.languages.c')
M.javascript = require('neoplayground.languages.javascript')
M.elixir = require('neoplayground.languages.elixir')

return M
