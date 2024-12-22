-- lua/neoplayground/languages/swift.lua
local base = require("neoplayground.languages.base")

-- Create new language instance
local Swift = base.new({
	name = "swift",
	file_pattern = "*.swift",
	command_name = "SwiftPlaygroundStart",
})

-- Override execute function for Swift
function Swift:execute(content, num_lines)
	-- First validate the setup
	local valid, err = self:validate()
	if not valid then
		return self:format_error(err)
	end

	-- Get language configuration
	local config = self:get_config()

	-- Add imports and helper functions if not present
	local imports = [[
import Foundation

// Helper function to capture variable values
func describe(_ value: Any) -> String {
    let mirror = Mirror(reflecting: value)
    if mirror.children.isEmpty {
        return "\(value)"
    }
    return String(describing: value)
}
]]

	-- Process content to capture variable values and prints
	local processed_content = imports .. "\n"

	-- Add line printing functionality
	for line in content:gmatch("[^\r\n]+") do
		if line:match("^%s*[%w_]+%s*$") then
			-- If line is just a variable, print its value
			local var = line:match("^%s*([%w_]+)%s*$")
			processed_content = processed_content .. string.format('print("\\(describe(%s))")\n', var)
		else
			processed_content = processed_content .. line .. "\n"
		end
	end

	-- Create temporary file
	local temp_file = self:create_temp_file(processed_content, ".swift")

	-- Prepare output lines
	local output_lines = self:prepare_output_lines(num_lines)

	-- Execute Swift code with timeout
	local success, result = self:with_timeout(function()
		local swift_cmd = string.format("%s %s", config.executor.command, temp_file)
		return self:capture_command(swift_cmd)
	end)

	-- Cleanup
	self:cleanup_temp_file(temp_file)

	if not success then
		return self:format_error(result)
	end

	-- Process output
	local current_line = 1
	for line in result:gmatch("[^\r\n]+") do
		-- Skip Swift compiler messages
		if not line:match("^%[.*%]") then
			if current_line <= num_lines then
				output_lines[current_line] = line
				current_line = current_line + 1
			end
		end
	end

	return output_lines
end

-- Helper function to check Swift tools
function Swift:check_tools()
	local tools = {
		"swift",
		"swiftc",
	}

	for _, tool in ipairs(tools) do
		if vim.fn.executable(tool) ~= 1 then
			return false, string.format("Swift tool '%s' not found", tool)
		end
	end

	return true
end

return Swift
