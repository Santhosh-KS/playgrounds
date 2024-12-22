-- lua/neoplayground/languages/go.lua
local base = require('neoplayground.languages.base')

-- Create new language instance
local Go = base.new({
    name = "go",
    file_pattern = "*.go",
    command_name = "GoPlaygroundStart"
})

-- Override execute function for Go
function Go:execute(content, num_lines)
    -- First validate the setup
    local valid, err = self:validate()
    if not valid then
        return self:format_error(err)
    end

    -- Get language configuration
    local config = self:get_config()

    -- Add main package and imports if not present
    if not content:match("package%s+main") then
        local imports = [[
package main

import (
    "fmt"
    "reflect"
)

]]
        content = imports .. content
    end

    -- Add main function if not present
    if not content:match("func%s+main%s*%(") then
        content = content .. [[

func main() {
    // Auto-generated main function
    __USER_CODE__
}
]]
    end

    -- Create a temporary file for the Go code
    local temp_dir = os.tmpname()
    os.remove(temp_dir)
    os.execute('mkdir -p ' .. temp_dir)
    
    local source_file = temp_dir .. '/main.go'
    local output_file = temp_dir .. '/main'

    -- Process the content to capture prints and values
    local processed_content = content:gsub("__USER_CODE__", function()
        local lines = {}
        for line in content:gmatch("[^\r\n]+") do
            -- Skip package, import, and function declarations
            if not line:match("^%s*package%s+") and
               not line:match("^%s*import%s+") and
               not line:match("^%s*func%s+") then
                
                -- If line is just a variable, wrap it in a print
                if line:match("^%s*[%w_]+%s*$") then
                    local var = line:match("^%s*([%w_]+)%s*$")
                    line = string.format('fmt.Printf("%%v\\n", %s)', var)
                end
                table.insert(lines, line)
            end
        end
        return table.concat(lines, "\n")
    end)

    -- Write to source file
    local f = io.open(source_file, 'w')
    f:write(processed_content)
    f:close()

    -- Prepare output lines
    local output_lines = self:prepare_output_lines(num_lines)

    -- Build flags from config
    local build_flags = table.concat(config.executor.build_flags or {}, " ")

    -- Compile the code
    local compile_cmd = string.format(
        "%s build %s -o %s %s",
        config.executor.command,
        build_flags,
        output_file,
        source_file
    )

    local compile_success, compile_result = self:capture_command(compile_cmd)
    if not compile_success then
        -- Cleanup
        os.execute('rm -rf ' .. temp_dir)
        return self:format_error("Compilation error:\n" .. compile_result)
    end

    -- Execute the compiled program
    local success, result = self:with_timeout(function()
        return self:capture_command(output_file)
    end)

    -- Cleanup
    os.execute('rm -rf ' .. temp_dir)

    if not success then
        return self:format_error(result)
    end

    -- Process output
    local current_line = 1
    for line in result:gmatch("[^\r\n]+") do
        if current_line <= num_lines then
            output_lines[current_line] = line
            current_line = current_line + 1
        end
    end

    return output_lines
end

-- Helper function to format Go code
function Go:format_code(content)
    local temp_file = self:create_temp_file(content, '.go')
    local result = self:capture_command("gofmt " .. temp_file)
    self:cleanup_temp_file(temp_file)
    return result
end

return Go
