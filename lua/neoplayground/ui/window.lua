-- lua/neoplayground/ui/window.lua
local M = {}
local config = require('neoplayground.config')

-- Store window state
M.state = {
    output_buf = nil,  -- Buffer number for output window
    output_win = nil,  -- Window number for output window
    original_win = nil -- Original window before split
}

-- Create or get output window
function M.create_output_window()
    -- If window exists and is valid, return it
    if M.state.output_win and vim.api.nvim_win_is_valid(M.state.output_win) then
        return M.state.output_win
    end

    -- Store current window
    M.state.original_win = vim.api.nvim_get_current_win()

    -- Get config
    local conf = config.get_general()
    local ui_conf = config.get_ui_config()

    -- Calculate width
    local width = math.floor(vim.o.columns * conf.split_width)

    -- Create the split
    if conf.split_position == 'right' then
        vim.cmd('botright vnew')
    else
        vim.cmd('topleft vnew')
    end

    -- Store new window
    M.state.output_win = vim.api.nvim_get_current_win()

    -- Create or get output buffer
    if not M.state.output_buf or not vim.api.nvim_buf_is_valid(M.state.output_buf) then
        M.state.output_buf = vim.api.nvim_create_buf(false, true)
        
        -- Set buffer options
        local buf_options = {
            buftype = 'nofile',
            bufhidden = 'hide',
            swapfile = false,
            modifiable = true,
            filetype = 'playground-output'
        }
        
        for option, value in pairs(buf_options) do
            vim.api.nvim_buf_set_option(M.state.output_buf, option, value)
        end
    end

    -- Set the buffer in the output window
    vim.api.nvim_win_set_buf(M.state.output_win, M.state.output_buf)

    -- Set window options
    local win_options = {
        wrap = false,
        cursorline = true,
        number = conf.show_line_numbers,
        relativenumber = false,
        signcolumn = 'no',
        foldcolumn = '0',
        list = false
    }

    for option, value in pairs(win_options) do
        vim.api.nvim_win_set_option(M.state.output_win, option, value)
    end

    -- Set window width
    vim.api.nvim_win_set_width(M.state.output_win, width)

    -- Add window border if configured
    if ui_conf.border and ui_conf.border ~= 'none' then
        vim.api.nvim_win_set_config(M.state.output_win, {
            border = ui_conf.border
        })
    end

    -- Return to original window
    vim.api.nvim_set_current_win(M.state.original_win)

    return M.state.output_win
end

-- Update window content
function M.update_content(content_lines)
    if not M.state.output_buf or not vim.api.nvim_buf_is_valid(M.state.output_buf) then
        return
    end

    -- Make buffer modifiable
    vim.api.nvim_buf_set_option(M.state.output_buf, 'modifiable', true)

    -- Clear the buffer
    vim.api.nvim_buf_set_lines(M.state.output_buf, 0, -1, false, {})

    -- Add new content
    vim.api.nvim_buf_set_lines(M.state.output_buf, 0, -1, false, content_lines)

    -- Make buffer non-modifiable
    vim.api.nvim_buf_set_option(M.state.output_buf, 'modifiable', false)
end

-- Clean up resources
function M.cleanup()
    if M.state.output_buf and vim.api.nvim_buf_is_valid(M.state.output_buf) then
        vim.api.nvim_buf_delete(M.state.output_buf, { force = true })
    end
    
    if M.state.output_win and vim.api.nvim_win_is_valid(M.state.output_win) then
        vim.api.nvim_win_close(M.state.output_win, true)
    end

    M.state.output_buf = nil
    M.state.output_win = nil
    M.state.original_win = nil
end

-- Handle window resize
function M.handle_resize()
    if M.state.output_win and vim.api.nvim_win_is_valid(M.state.output_win) then
        local conf = config.get_general()
        local width = math.floor(vim.o.columns * conf.split_width)
        vim.api.nvim_win_set_width(M.state.output_win, width)
    end
end

-- Set window options
function M.set_options(win_id, options)
    if win_id and vim.api.nvim_win_is_valid(win_id) then
        for option, value in pairs(options) do
            vim.api.nvim_win_set_option(win_id, option, value)
        end
    end
end

-- Check if window is playground window
function M.is_playground_window(win_id)
    return win_id == M.state.output_win
end

return M
