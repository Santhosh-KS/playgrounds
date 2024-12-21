-- lua/neoplayground/languages/lua.lua
local base = require('neoplayground.languages.base')

-- Create new language instance
local Lua = base.new({
    name = "lua",
    file_pattern = "*.lua",
    command_name = "LuaPlaygroundStart"
})

-- Override execute function for Lua
function Lua:execute(content, num_lines)
    -- First validate the setup
    local valid, err = self:validate()
    if not valid then
        return self:format_error(err)
    end

    -- Get language configuration
    local config = self:get_config()

    -- Prepare output lines
    local output_lines = self:prepare_output_lines(num_lines)

    -- Modify the content to capture prints and returns
    local modified_content = [[
        local _playground_output = {}
        local _playground_line = 0
        local _original_print = print
        
        -- Override print function
        function print(...)
            local args = {...}
            local result = {}
            for i, v in ipairs(args) do
                table.insert(result, tostring(v))
            end
            _playground_output[_playground_line] = table.concat(result, '\t')
        end

        -- Execute each line
        local function execute_line(line, line_num)
            _playground_line = line_num
            -- Try to evaluate as expression first
            local success, result = pcall(load('return ' .. line))
            if success and result ~= nil then
                _playground_output[line_num] = vim.inspect(result)
            else
                -- Execute as statement
                success, result = pcall(load(line))
                if not success then
                    _playground_output[line_num] = 'Error: ' .. tostring(result)
                end
            end
        end
    ]]

    -- Process each line
    local line_num = 1
    for line in content:gmatch("[^\r\n]+") do
        if line:match("%S") then  -- Skip empty lines
            modified_content = modified_content .. string.format(
                "\npcall(function() execute_line([=[%s]=], %d) end)",
                line, line_num
            )
        end
        line_num = line_num + 1
    end

    -- Execute the modified content
    local func = load(modified_content)
    if not func then
        return self:format_error("Failed to parse Lua code")
    end

    local success, result = pcall(func)
    if not success then
        return self:format_error(result)
    end

    -- Get output
    for line_num, output in pairs(_playground_output) do
        if line_num <= num_lines then
            output_lines[line_num] = output
        end
    end

    return output_lines
end

return Lua
