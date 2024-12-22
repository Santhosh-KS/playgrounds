-- lua/neoplayground/languages/swift.lua
local base = require("neoplayground.languages.base")

-- Create new language instance for Swift
local Swift = base.Language.new({
	name = "swift",
	file_pattern = "*.swift",
	command_name = "SwiftPlaygroundStart",
})

-- Override execute method for Swift
function Swift:execute(content, num_lines)
	-- Validate setup
	local valid, err = self:validate()
	if not valid then
		return self:format_error(err)
	end

	-- Get configuration
	local config = self:get_config()

	-- Prepare output lines
	local output_lines = {}
	for i = 1, num_lines do
		output_lines[i] = ""
	end

	-- Create temporary file with content
	local temp_file = self:create_temp_file(content, ".swift")
	if not temp_file then
		return self:format_error("Failed to create temporary file")
	end

	-- Execute Swift code
	local success, result = self:capture_command(string.format("swift %s", temp_file))

	-- Cleanup
	self:cleanup_temp_file(temp_file)

	-- Handle execution result
	if not success then
		return self:format_error(result)
	end

	-- Process output
	local line_num = 1
	for line in result:gmatch("[^\r\n]+") do
		if line_num <= num_lines then
			output_lines[line_num] = line
			line_num = line_num + 1
		end
	end

	return output_lines
end

return Swift
