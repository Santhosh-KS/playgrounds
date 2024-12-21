-- lua/neoplayground/ui/highlights.lua
local M = {}
local config = require('neoplayground.config')

-- Define highlight groups
local highlights = {
    PlaygroundOutput = {
        default = true,
        link = 'Normal'
    },
    PlaygroundError = {
        default = true,
        link = 'Error'
    },
    PlaygroundWarning = {
        default = true,
        link = 'WarningMsg'
    },
    PlaygroundInfo = {
        default = true,
        link = 'Comment'
    },
    PlaygroundSuccess = {
        default = true,
        link = 'String'
    },
    PlaygroundLineNumber = {
        default = true,
        link = 'LineNr'
    },
    PlaygroundBorder = {
        default = true,
        link = 'FloatBorder'
    }
}

-- Setup function to create highlight groups
function M.setup()
    -- Get UI configuration
    local ui_config = config.get_ui_config()

    -- Create highlight groups
    for group_name, group_settings in pairs(highlights) do
        -- Check if custom highlight is defined in config
        local custom_hl = ui_config.highlight and ui_config.highlight[group_name:lower()]
        
        if custom_hl then
            -- Use custom highlight settings
            vim.api.nvim_set_hl(0, group_name, custom_hl)
        else
            -- Use default link
            vim.api.nvim_set_hl(0, group_name, {
                default = group_settings.default,
                link = group_settings.link
            })
        end
    end

    -- Set up syntax matching
    local syntax_rules = {
        -- Error highlighting
        {'match', 'PlaygroundError', '^Error:.*$'},
        {'match', 'PlaygroundError', '^.*Exception:.*$'},
        {'match', 'PlaygroundError', '^.*Error:.*$'},
        
        -- Warning highlighting
        {'match', 'PlaygroundWarning', '^Warning:.*$'},
        {'match', 'PlaygroundWarning', '^.*Warning:.*$'},
        
        -- Success highlighting
        {'match', 'PlaygroundSuccess', '^Success:.*$'},
        {'match', 'PlaygroundSuccess', '^=>.*$'},
        
        -- Info highlighting
        {'match', 'PlaygroundInfo', '^Info:.*$'},
        {'match', 'PlaygroundInfo', '^#.*$'},
    }

    -- Create syntax commands
    for _, rule in ipairs(syntax_rules) do
        local cmd = string.format('syntax %s %s /%s/', rule[1], rule[2], rule[3])
        vim.cmd(cmd)
    end
end

-- Apply highlights to a specific window
function M.apply_to_window(win_id)
    if win_id and vim.api.nvim_win_is_valid(win_id) then
        local buf = vim.api.nvim_win_get_buf(win_id)
        vim.api.nvim_buf_set_option(buf, 'syntax', 'playground-output')
    end
end

-- Create a new highlight group
function M.create_highlight(group_name, settings)
    vim.api.nvim_set_hl(0, group_name, settings)
end

-- Get highlight group settings
function M.get_highlight(group_name)
    return vim.api.nvim_get_hl_by_name(group_name, true)
end

-- Clear all playground highlights
function M.clear_highlights()
    for group_name, _ in pairs(highlights) do
        pcall(vim.api.nvim_del_hl_namespace_by_name, group_name)
    end
end

return M
