-- lua/neoplayground/utils.lua
local M = {}

-- File operations
function M.create_temp_file(content, extension)
    local temp_file = os.tmpname() .. (extension or '')
    local f = io.open(temp_file, 'w')
    if not f then
        error("Failed to create temporary file")
    end
    f:write(content)
    f:close()
    return temp_file
end

function M.cleanup_temp_file(file)
    if file then
        os.remove(file)
    end
end

-- Path operations
function M.join_paths(...)
    local sep = package.config:sub(1,1) -- Path separator based on OS
    return table.concat({...}, sep)
end

-- String operations
function M.trim(s)
    return s:match("^%s*(.-)%s*$")
end

function M.split_lines(s)
    local lines = {}
    for line in s:gmatch("[^\r\n]+") do
        table.insert(lines, line)
    end
    return lines
end

-- Table operations
function M.merge_tables(t1, t2)
    local result = vim.deepcopy(t1)
    for k, v in pairs(t2) do
        if type(v) == "table" and type(result[k]) == "table" then
            result[k] = M.merge_tables(result[k], v)
        else
            result[k] = v
        end
    end
    return result
end

-- System operations
function M.get_os()
    local sysname = vim.loop.os_uname().sysname
    return string.lower(sysname)
end

function M.is_executable(cmd)
    return vim.fn.executable(cmd) == 1
end

-- Command execution with timeout
function M.execute_with_timeout(cmd, timeout)
    timeout = timeout or 5000 -- Default 5 seconds
    
    local result = nil
    local done = false
    
    local thread = vim.loop.new_thread(function()
        local handle = io.popen(cmd .. " 2>&1")
        if handle then
            result = handle:read("*a")
            handle:close()
        end
        done = true
    end)
    
    local start_time = vim.loop.now()
    while not done do
        if vim.loop.now() - start_time > timeout then
            if thread then
                thread:cancel()
            end
            return false, "Execution timed out"
        end
        vim.loop.sleep(10)
    end
    
    return true, result
end

-- Error handling
function M.format_error(err_msg)
    if type(err_msg) == "string" then
        return "Error: " .. err_msg
    elseif type(err_msg) == "table" then
        return "Error: " .. vim.inspect(err_msg)
    else
        return "Unknown error occurred"
    end
end

-- Window utilities
function M.get_win_config(options)
    local columns = vim.o.columns
    local lines = vim.o.lines
    local width = math.floor(columns * (options.width or 0.8))
    local height = math.floor(lines * (options.height or 0.8))
    
    return {
        relative = 'editor',
        row = math.floor((lines - height) / 2),
        col = math.floor((columns - width) / 2),
        width = width,
        height = height,
        style = 'minimal',
        border = options.border or 'rounded'
    }
end

-- Buffer utilities
function M.create_scratch_buffer(options)
    options = options or {}
    local buf = vim.api.nvim_create_buf(false, true)
    
    local buf_options = {
        buftype = 'nofile',
        bufhidden = 'hide',
        swapfile = false,
        modifiable = true
    }
    
    for k, v in pairs(buf_options) do
        vim.api.nvim_buf_set_option(buf, k, v)
    end
    
    if options.filetype then
        vim.api.nvim_buf_set_option(buf, 'filetype', options.filetype)
    end
    
    return buf
end

return M
