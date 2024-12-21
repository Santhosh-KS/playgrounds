-- lua/neoplayground/ui/init.lua
local M = {}
local window = require('neoplayground.ui.window')
local highlights = require('neoplayground.ui.highlights')

-- Initialize the UI module
function M.setup()
    -- Set up highlights
    highlights.setup()
end

-- Create or get output window
function M.create_output_window()
    return window.create_output_window()
end

-- Update output window content
function M.update_output_window(content_lines)
    window.update_content(content_lines)
end

-- Clean up UI resources
function M.cleanup()
    window.cleanup()
end

-- Get window information
function M.get_windows()
    return window.get_windows()
end

-- Set window options
function M.set_window_options(win_id, options)
    window.set_options(win_id, options)
end

-- Check if a window is a playground window
function M.is_playground_window(win_id)
    return window.is_playground_window(win_id)
end

-- Refresh UI
function M.refresh()
    window.refresh()
end

-- Handle window resize
function M.handle_resize()
    window.handle_resize()
end

-- Set content filetype
function M.set_filetype(filetype)
    window.set_filetype(filetype)
end

return M
