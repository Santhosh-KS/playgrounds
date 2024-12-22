-- lua/neoplayground/languages/go.lua
local base = require("neoplayground.languages.base")

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
	-- Initialize output_lines with empty strings for all lines
	local output_lines = {}
	local buffer_lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
	for i = 1, #buffer_lines do
		output_lines[i] = ""
	end

	local ok, result = pcall(function()
		-- Create temporary directory
		local temp_dir = vim.fn.tempname()
		vim.fn.mkdir(temp_dir, "p")

		local source_file = temp_dir .. "/main.go"
		local binary_file = temp_dir .. "/main"

		-- Get buffer content
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
			return { "Error: Failed to create Go source file" }
		end
		file:write(file_content)
		file:close()

		-- Build and run
		local build_cmd = string.format("/snap/bin/go build -o %s %s", binary_file, source_file)
		local build_result = vim.fn.system(build_cmd)

		if vim.v.shell_error ~= 0 then
			return { "Build error: " .. build_result }
		end

		local run_result = vim.fn.system(binary_file)
		if vim.v.shell_error ~= 0 then
			return { "Run error: " .. run_result }
		end

		-- Process output line by line
		local output_line_num = 1
		for i, line in ipairs(buffer_lines) do
			-- If line has a print statement, assign output to it
			if line:match("fmt.Print") then
				local output = ""
				if output_line_num <= #output_lines then
					local next_output = run_result:match("([^\n]*)\n?")
					if next_output then
						output = next_output
						run_result = run_result:sub(#next_output + 2) -- +2 for \n
					end
				end
				output_lines[i] = output
				output_line_num = output_line_num + 1
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

return instance
