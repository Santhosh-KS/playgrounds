-- lua/neoplayground/languages/swift.lua
local base = require('neoplayground.languages.base')

-- Create new language instance
local Swift = base.new({
    name = "swift",
    file_pattern = "*.swift",
    command_name = "SwiftPlaygroundStart"
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
            local var = line:match("^%s*([%w_]+)%
