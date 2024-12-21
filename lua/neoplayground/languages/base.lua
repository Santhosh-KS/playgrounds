-- lua/neoplayground/languages/base.lua
local M = {}

-- Base language class
local Language = {}
Language.__index = Language

-- Constructor for base language
function Language.new(opts)
    local self = setmetatable({}, Language)
    
    -- Required fields
    self.name = opts.name or "unnamed"
    self.file_pattern = opts.file_pattern or "*"
    self.command_name = opts.command_name or "PlaygroundStart"
    
    -- Optional fields with defaults
    self.executor = opts.executor or {}
    self.show_return_value = opts.show_return_value or true
    self.timeout = opts.timeout or 5000 -- milliseconds
    
    return self
end

-- Function to create temporary file
function Language:create_temp_file(content, extension)
    local temp_file = os.tmpname() .. (extension or '')
    local f = io.open(temp_file, 'w')
    if not f then
        error("Failed to create temporary file")
    end
    f:write(content)
    f:close()
    return temp_file
end

-- Function to remove temporary file
function Language:cleanup_temp_file(file)
    if file then
        os.remove(file)
    end
end

-- Base execute function (should be overridden by language implementations)
function Language:execute(content, num_lines)
    error("Execute method must be implemented by language modules")
end

-- Function to capture command output
function Language:capture_command(cmd)
    local handle = io.popen(cmd .. " 2>&1")
    if not handle then
        return false, "Failed to execute command"
    end
    
    local result = handle:read("*a")
    local success = handle:close()
    
    return success, result
end

-- Function to prepare output lines
function Language:prepare_output_lines(output, num_lines)
    local lines = {}
    -- Initialize with empty lines
    for i = 1, num_lines do
        lines[i] = ""
    end
    return lines
end

-- Function to handle execution timeout
function Language:with_timeout(func, timeout)
    local result = nil
    local done = false
    local thread = vim.loop.new_thread(function()
        result = func()
        done = true
    end)
    
    local start_time = vim.loop.now()
    while not done do
        if vim.loop.now() - start_time > (timeout or self.timeout) then
            -- Cleanup and return error
            if thread then
                thread:cancel()
            end
            return false, "Execution timed out"
        end
        vim.loop.sleep(10)
    end
    
    return true, result
end

-- Function to format error message
function Language:format_error(err_msg)
    return {
        "Error: " .. tostring(err_msg)
    }
end

-- Function to check if an executable exists
function Language:check_executable(cmd)
    return vim.fn.executable(cmd) == 1
end

-- Function to get language configuration
function Language:get_config()
    local config = require('neoplayground.config')
    return config.get_language_config(self.name)
end

-- Function to validate language setup
function Language:validate()
    local lang_config = self:get_config()
    if not lang_config then
        return false, "Language configuration not found"
    end
    
    if not self:check_executable(lang_config.executor.command) then
        return false, string.format("Executable '%s' not found", lang_config.executor.command)
    end
    
    return true, nil
end

-- Create new language instance helper
function M.new(opts)
    return Language.new(opts)
end

-- Export the Language class
M.Language = Language

return M
