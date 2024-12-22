-- lua/neoplayground/init.lua

-- Main plugin module
local M = {}

-- Import required modules
local config = require('neoplayground.config')
local ui = require('neoplayground.ui')
local langs = require('neoplayground.languages')

-- Plugin state
M.state = {
    initialized = false,
    current_lang = nil,
    windows = {
        output_buf = nil,
        output_win = nil,
    }
}

-- Setup function that will be called by lazy.nvim
function M.setup(opts)
    if M.state.initialized then
        return
    end

    -- Initialize configuration
    config.setup(opts)

    -- Create autocommand group
    local augroup = vim.api.nvim_create_augroup("NeoPlayground", { clear = true })

    -- Register commands and autocommands for each enabled language
    for lang_name, lang_config in pairs(config.get_languages()) do
        if lang_config.enabled then
            local lang = langs.get_language(lang_name)
            if lang then
                -- Create language-specific autocommand
                vim.api.nvim_create_autocmd("BufWritePost", {
                    group = augroup,
                    pattern = lang.file_pattern,
                    callback = function()
                        local current_buf = vim.api.nvim_get_current_buf()
                        if vim.b[current_buf].is_playground then
                            M.update_output(current_buf, lang_name)
                        end
                    end,
                })

                -- Create language-specific command
                vim.api.nvim_create_user_command(lang.command_name, function()
                    M.start_playground(lang_name)
                end, {
                    desc = string.format("Start %s playground", lang_name)
                })
            end
        end
    end

    M.state.initialized = true
end

-- Function to start playground for a specific language
function M.start_playground(lang_name)
    local lang = langs.get_language(lang_name)
    if not lang then
        vim.notify(
            string.format("Language '%s' not supported", lang_name),
            vim.log.levels.ERROR
        )
        return
    end

    -- Set buffer local variables
    vim.b.is_playground = true
    vim.b.playground_lang = lang_name
    M.state.current_lang = lang_name

    -- Create or update UI
    ui.create_output_window()

    -- Initial update
    M.update_output(vim.api.nvim_get_current_buf(), lang_name)
end

-- Function to update output
function M.update_output(buf, lang_name)
    -- Ensure UI is ready
    ui.create_output_window()

    -- Get the language handler
    local lang = langs.get_language(lang_name)
    if not lang then
        vim.notify(
            string.format("Language '%s' not found", lang_name),
            vim.log.levels.ERROR
        )
        return
    end

    -- Get buffer content
    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    local content = table.concat(lines, '\n')

    -- Execute code and get output
    local success, output_lines = pcall(lang.execute, content, #lines)

    if not success then
        output_lines = {
            string.format("Error executing %s code:", lang_name),
            output_lines
        }
    end

    -- Update output window
    ui.update_output_window(output_lines)
end

-- Function to stop playground
function M.stop_playground()
    vim.b.is_playground = false
    vim.b.playground_lang = nil
    M.state.current_lang = nil
    ui.cleanup()
end

return M
