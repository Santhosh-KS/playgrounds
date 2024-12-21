-- lua/neoplayground/languages/python.lua
local base = require('neoplayground.languages.base')

-- Create new language instance
local Python = base.new({
    name = "python",
    file_pattern = "*.py",
    command_name = "PythonPlaygroundStart"
})

-- Override execute function for Python
function Python:execute(content, num_lines)
    -- First validate the setup
    local valid, err = self:validate()
    if not valid then
        return self:format_error(err)
    end

    -- Get language configuration
    local config = self:get_config()

    -- Create wrapper code to capture output and variable values
    local wrapped_content = [[
import sys
from io import StringIO
import traceback
import inspect
import ast

class OutputCapture:
    def __init__(self):
        self.outputs = {}
        self.current_line = 0

    def write(self, text):
        if self.current_line not in self.outputs:
            self.outputs[self.current_line] = []
        self.outputs[self.current_line].append(text)

# Create output capture
output_capture = OutputCapture()
original_stdout = sys.stdout
sys.stdout = output_capture

try:
    # Split code into lines for line-by-line execution
    code_lines = """]] .. content .. [[""".splitlines()
    
    globals_dict = {}
    locals_dict = {}
    
    for line_num, line in enumerate(code_lines, 1):
        output_capture.current_line = line_num
        if line.strip():  # Skip empty lines
            try:
                # Try to evaluate as expression first
                try:
                    tree = ast.parse(line, mode='eval')
                    result = eval(compile(tree, '<string>', 'eval'), globals_dict, locals_dict)
                    if result is not None:
                        print(repr(result))
                except SyntaxError:
                    # If not an expression, execute as statement
                    tree = ast.parse(line, mode='exec')
                    exec(compile(tree, '<string>', 'exec'), globals_dict, locals_dict)
            except Exception as e:
                print(f"Error: {str(e)}")

except Exception as e:
    print(f"Error: {str(e)}")
    print(traceback.format_exc())

finally:
    # Restore original stdout
    sys.stdout = original_stdout
    
# Print captured output in a format we can parse
print("---PLAYGROUND_OUTPUT---")
for line_num, outputs in sorted(output_capture.outputs.items()):
    print(f"{line_num}:{':'.join(outputs)}")
]]

    -- Create temporary file
    local temp_file = self:create_temp_file(wrapped_content, '.py')

    -- Prepare output lines
    local output_lines = self:prepare_output_lines(num_lines)

    -- Execute Python code with timeout
    local success, result = self:with_timeout(function()
        -- Get Python executable from config
        local python_cmd = config.executor.command
        if config.executor.virtual_env then
            python_cmd = config.executor.virtual_env .. "/bin/python"
        end
        
        return self:capture_command(python_cmd .. " " .. temp_file)
    end)

    -- Cleanup
    self:cleanup_temp_file(temp_file)

    if not success then
        return self:format_error(result)
    end

    -- Process the output
    local capture_started = false
    for line in result:gmatch("[^\r\n]+") do
        if line == "---PLAYGROUND_OUTPUT---" then
            capture_started = true
        elseif capture_started then
            local line_num, content = line:match("(%d+):(.+)")
            if line_num and content then
                output_lines[tonumber(line_num)] = content:gsub("\n", "")
            end
        end
    end

    return output_lines
end

-- Helper function to check for virtual environment
function Python:check_venv()
    local config = self:get_config()
    if config.executor.virtual_env then
        local venv_python = config.executor.virtual_env .. "/bin/python"
        return vim.fn.executable(venv_python) == 1
    end
    return true
end

return Python
