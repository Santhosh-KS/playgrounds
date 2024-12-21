-- lua/neoplayground/languages/c.lua
local base = require('neoplayground.languages.base')
local utils = require('neoplayground.utils')

-- Create new language instance
local C = base.new({
    name = "c",
    file_pattern = "*.c",
    command_name = "CPlaygroundStart"
})

-- Override execute function for C
function C:execute(content, num_lines)
    -- First validate the setup
    local valid, err = self:validate()
    if not valid then
        return self:format_error(err)
    end

    -- Get language configuration
    local config = self:get_config()
    local compile_flags = table.concat(config.executor.compile_flags or {}, " ")

    -- Create temporary files
    local source_file = self:create_temp_file(content, ".c")
    local output_file = source_file .. ".out"

    -- Add main function if not present
    if not content:match("int%s+main%s*%(") then
        content = [[
#include <stdio.h>
#include <stdlib.h>

// Function prototypes for user code
__USER_CODE__

int main() {
    __USER_CODE__
    return 0;
}
        ]]
        content = content:gsub("__USER_CODE__", content)
        
        -- Write modified content
        local f = io.open(source_file, 'w')
        f:write(content)
        f:close()
    end

    -- Prepare output lines
    local output_lines = self:prepare_output_lines(num_lines)

    -- Compile the code
    local compile_cmd = string.format(
        "%s %s %s -o %s", 
        config.executor.command,
        source_file,
        compile_flags,
        output_file
    )

    local compile_success, compile_result = self:capture_command(compile_cmd)
    
    if not compile_success then
        -- Cleanup
        self:cleanup_temp_file(source_file)
        self:cleanup_temp_file(output_file)
        return self:format_error("Compilation error:\n" .. compile_result)
    end

    -- Execute the compiled program
    local success, result = self:with_timeout(function()
        local exec_success, exec_result = self:capture_command(output_file)
        return {success = exec_success, result = exec_result}
    end)

    -- Cleanup
    self:cleanup_temp_file(source_file)
    self:cleanup_temp_file(output_file)

    if not success then
        return self:format_error(result)
    end

    -- Process output
    local current_line = 1
    for line in result.result:gmatch("[^\r\n]+") do
        if current_line <= num_lines then
            output_lines[current_line] = line
            current_line = current_line + 1
        end
    end

    return output_lines
end

-- Add C-specific helper functions
function C:inject_headers(content)
    local headers = [[
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
]]
    return headers .. "\n" .. content
end

function C:parse_print_statements(content)
    -- Convert simple variable prints to printf statements
    local lines = {}
    for line in content:gmatch("[^\r\n]+") do
        -- Check if line is just a variable name
        if line:match("^%s*[%w_]+%s*$") then
            local var = line:match("^%s*([%w_]+)%s*$")
            line = string.format('printf("%%d\\n", %s);', var)
        end
        table.insert(lines, line)
    end
    return table.concat(lines, "\n")
end

return C
