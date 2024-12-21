
-- lua/neoplayground/languages/javascript.lua
local base = require('neoplayground.languages.base')

-- Create new language instance
local JavaScript = base.new({
    name = "javascript",
    file_pattern = "*.js",
    command_name = "JavaScriptPlaygroundStart"
})

function JavaScript:execute(content, num_lines)
    -- Validate setup
    local valid, err = self:validate()
    if not valid then
        return self:format_error(err)
    end

    -- Get language configuration
    local config = self:get_config()

    -- Add console.log capture wrapper
    local wrapped_content = [[
const util = require('util');
const output = new Map();
let currentLine = 0;

// Store original console.log
const originalLog = console.log;

// Override console.log
console.log = (...args) => {
    output.set(currentLine, args.map(arg => 
        typeof arg === 'object' ? util.inspect(arg, {depth: null}) : String(arg)
    ).join(' '));
};

try {
    // Execute each line
    const lines = `]] .. content .. [[`.split('\n');
    
    for (let i = 0; i < lines.length; i++) {
        currentLine = i + 1;
        const line = lines[i].trim();
        if (line) {
            try {
                // Try as expression first
                const result = eval(line);
                if (result !== undefined) {
                    output.set(currentLine, util.inspect(result, {depth: null}));
                }
            } catch {
                // Execute as statement
                eval(line);
            }
        }
    }
} catch (error) {
    console.log(`Error: ${error.message}`);
} finally {
    console.log = originalLog;
    console.log('---PLAYGROUND_OUTPUT---');
    for (const [line, content] of output.entries()) {
        console.log(`${line}:${content}`);
    }
}
]]

    -- Create temporary file
    local temp_file = self:create_temp_file(wrapped_content, '.js')

    -- Prepare output lines
    local output_lines = self:prepare_output_lines(num_lines)

    -- Execute JavaScript code
    local success, result = self:with_timeout(function()
        local node_cmd = string.format("node %s", temp_file)
        return self:capture_command(node_cmd)
    end)

    -- Cleanup
    self:cleanup_temp_file(temp_file)

    if not success then
        return self:format_error(result)
    end

    -- Process output
    local capture_started = false
    for line in result:gmatch("[^\r\n]+") do
        if line == "---PLAYGROUND_OUTPUT---" then
            capture_started = true
        elseif capture_started then
            local line_num, content = line:match("(%d+):(.+)")
            if line_num and content then
                output_lines[tonumber(line_num)] = content
            end
        end
    end

    return output_lines
end

return JavaScript
