-- plugin/neoplayground.lua
if vim.g.loaded_neoplayground then
    return
end
vim.g.loaded_neoplayground = 1

-- Create user commands and autocommands
local function setup_commands()
    -- Command to toggle playground on/off
    vim.api.nvim_create_user_command('PlaygroundToggle', function()
        local playground = require('neoplayground')
        if vim.b.is_playground then
            playground.stop_playground()
        else
            local filetype = vim.bo.filetype
            playground.start_playground(filetype)
        end
    end, {
        desc = "Toggle playground for current buffer"
    })

    -- Create autocommands group
    local group = vim.api.nvim_create_augroup("NeoPlayground", { clear = true })

    -- Handle window resize
    vim.api.nvim_create_autocmd("VimResized", {
        group = group,
        callback = function()
            local playground = require('neoplayground')
            playground.handle_resize()
        end,
    })

    -- Handle window close
    vim.api.nvim_create_autocmd("WinClosed", {
        group = group,
        callback = function(opts)
            local playground = require('neoplayground')
            if playground.is_playground_window(tonumber(opts.match)) then
                playground.cleanup()
            end
        end,
    })

    -- Handle buffer write
    vim.api.nvim_create_autocmd("BufWritePost", {
        group = group,
        callback = function(opts)
            if vim.b.is_playground then
                local playground = require('neoplayground')
                playground.update_output(opts.buf, vim.b.playground_lang)
            end
        end,
    })
end

-- Define highlight groups
local function setup_highlights()
    local highlights = require('neoplayground.ui.highlights')
    highlights.setup()
end

-- Initialize plugin
local function init()
    setup_commands()
    setup_highlights()
end

-- Defer initialization to next tick
vim.schedule(init)

-- Expose global setup function
_G.setup_neoplayground = function(opts)
    local playground = require('neoplayground')
    playground.setup(opts)
end

-- Return success
return true
