-- lua/neoplayground/languages/elixir.lua
local base = require('neoplayground.languages.base')

-- Create new language instance
local Elixir = base.new({
    name = "elixir",
    file_pattern = "*.ex",
    command_name = "ElixirPlaygroundStart"
})

function Elixir:execute(content, num_lines)
    -- Validate setup
    local valid, err = self:validate()
    if not valid then
        return self:format_error(err)
    end

    -- Get language configuration
    local config = self:get_config()

    -- Add output capture wrapper
    local wrapped_content = [[
output = :ets.new(:playground_output, [:set])

defmodule Playground do
  def capture_output(line_num, value) do
    :ets.insert(:playground_output, {line_num, inspect(value)})
  end
end

try do
  lines = """
]] .. content .. [[
  """
  |> String.split("\n")
  |> Enum.with_index(1)
  
  for {line, line_num} <- lines do
    try do
      {result, _} = Code.eval_string(line)
      if result != nil do
        Playground.capture_output(line_num, result)
      end
    rescue
      e -> Playground.capture_output(line_num, "Error: #{Exception.message(e)}")
    end
  end
after
  IO.puts("---PLAYGROUND_OUTPUT---")
  :ets.tab2list(output)
  |> Enum.sort()
  |> Enum.each(fn {line, content} -> 
    IO.puts("#{line}:#{content}")
  end)
end
]]

    -- Create temporary file
    local temp_file = self:create_temp_file(wrapped_content, '.exs')

    -- Prepare output lines
    local output_lines = self:prepare_output_lines(num_lines)

    -- Execute Elixir code
    local success, result = self:with_timeout(function()
        local elixir_cmd = string.format("elixir %s", temp_file)
        return self:capture_command(elixir_cmd)
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

return Elixir
