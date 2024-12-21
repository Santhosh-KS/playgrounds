-- lua/neoplayground/languages/cpp.lua
local base = require('neoplayground.languages.base')

-- Create new language instance
local CPP = base.new({
    name = "cpp",
    file_pattern = "*.cpp",
    command_name = "CppPlaygroundStart"
})

-- Override execute function for C++
function CPP:execute(content, num_lines)
    -- First validate the setup
    local valid, err = self:validate()
    if not valid then
        return self:format_error(err)
    end

    -- Get language configuration
    local config = self:get_config()
    local compile_flags = table.concat(config.executor.compile_flags or {}, " ")

    -- Add standard includes and helper functions if not present
    local includes = [[
#include <iostream>
#include <string>
#include <vector>
#include <memory>
#include <map>
#include <sstream>
#include <iomanip>
#include <any>

template<typename T>
std::string to_string_with_precision(const T value, const int precision = 6) {
    std::ostringstream out;
    out << std::fixed << std::setprecision(precision) << value;
    return out.str();
}

#define PRINT_VAR(x) std::cout << #x << ": " << x << std::endl
]]

    -- Add main function if not present
    if not content:match("int%s+main%s*%(") then
        local modified_content = includes .. "\n"
        modified_content = modified_content .. "int main() {\n"
        
        -- Process each line
        for line in content:gmatch("[^\r\n]+") do
            -- If line is just a variable, add print statement
            if line:match("^%s*[%w_]+%s*$") then
                local var = line:match("^%s*([%w_]+)%s*$")
                modified_content = modified_content .. 
                    string.format("    PRINT_VAR(%s);\n", var)
            else
                modified_content = modified_content .. "    " .. line .. "\n"
            end
        end
        
        modified_content = modified_content .. "    return 0;\n}\n"
        content = modified_content
    end

    -- Create temporary files
    local source_file = self:create_temp_file(content, ".cpp")
    local output_file = source_file .. ".out"

    -- Prepare output lines
    local output_lines = self:prepare_output_lines(num_lines)

    -- Compile the code
    local compile_cmd = string.format(
        "%s %s -o %s %s -std=c++17", 
        config.executor.command,
        source_file,
        output_file,
        compile_flags
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

-- Helper function to format C++ code
function CPP:format_code(content)
    -- Check if clang-format is available
    if vim.fn.executable('clang-format') == 1 then
        local temp_file = self:create_temp_file(content, '.cpp')
        local result = self:capture_command("clang-format " .. temp_file)
        self:cleanup_temp_file(temp_file)
        return result
    end
    return content
end

-- Helper function to get compiler version
function CPP:get_compiler_version()
    local config = self:get_config()
    local success, result = self:capture_command(config.executor.command .. " --version")
    return success and result or "Unknown compiler version"
end

return CPP
