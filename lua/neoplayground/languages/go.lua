-- lua/neoplayground/languages/go.lua
local base = require("neoplayground.languages.base")

-- Debug print function
local function debug_print(msg)
	print(string.format("[Go Plugin Debug] %s", msg))
end

-- debug_print("Loading Go plugin...")

-- Create new language instance for Go
local instance = base.Language.new({
	name = "go",
	file_pattern = "*.go",
	command_name = "GoPlaygroundStart",
	executor = {
		command = "/snap/bin/go",
		timeout = 5000,
	},
})

function instance:execute(content, num_lines)
	-- debug_print("Execute method called")
	num_lines = tonumber(num_lines) or 0

	local ok, result = pcall(function()
		-- Create temporary directory
		local temp_dir = vim.fn.tempname()
		vim.fn.mkdir(temp_dir, "p")
		-- debug_print("Created temp dir: " .. temp_dir)

		-- Create source and output file paths
		local source_file = temp_dir .. "/main.go"
		local binary_file = temp_dir .. "/main"
		-- debug_print("Source file: " .. source_file)
		-- debug_print("Binary file: " .. binary_file)

		-- Get buffer content
		local buffer_lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
		local buffer_content = table.concat(buffer_lines, "\n")

		-- Create Go file content
		local file_content = string.format(
			[[
package main

import (
    "fmt"
)

func main() {
    %s
}]],
			buffer_content
		)

		-- Write Go file
		local file = io.open(source_file, "w")
		if not file then
			error("Failed to create Go source file")
		end
		file:write(file_content)
		file:close()

		-- Build the program
		local build_cmd = string.format("/snap/bin/go build -o %s %s", binary_file, source_file)
		-- debug_print("Build command: " .. build_cmd)

		local build_result = vim.fn.system(build_cmd)
		if vim.v.shell_error ~= 0 then
			error("Build failed: " .. build_result)
		end

		-- Run the program
		-- debug_print("Running binary: " .. binary_file)
		local run_result = vim.fn.system(binary_file)

		if vim.v.shell_error ~= 0 then
			error("Run failed: " .. run_result)
		end

		-- Initialize output lines
		local output_lines = {}
		for i = 1, num_lines do
			output_lines[i] = ""
		end

		-- Process output

		local line_num = 1
		for line in run_result:gmatch("[^\r\n]+") do
			if line_num <= num_lines then
				output_lines[line_num] = line
				line_num = line_num + 1
			end
		end

		-- Cleanup
		vim.fn.delete(temp_dir, "rf")

		return output_lines
	end)

	if not ok then
		return { tostring(result) }
	end

	return result
end

-- debug_print("Go plugin loaded successfully")
return instance
