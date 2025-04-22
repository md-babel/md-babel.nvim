local md_babel = {}

---@return 1-based table of line and column
function md_babel.get_source_location()
  local pos = vim.api.nvim_win_get_cursor(0)
  local row, col = pos[1], pos[2]
  return { line = row, column = col + 1 }
end

function md_babel.execute_block_at_point()
  if vim.bo.filetype ~= "markdown" then
    vim.api.nvim_err_writeln("Not a Markdown file!")
    return
  end

  -- Get md-babel executable path from config
  local md_babel_path = vim.g.md_babel_executable_path
  if not md_babel_path then
    vim.api.nvim_err_writeln("md-babel executable path not set. Please set g:md_babel_executable_path")
    return
  end

  local location = md_babel.get_source_location()
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local document_text = table.concat(lines, "\n")

  -- Execute md-babel CLI, piping buffer content into it as standard input
  local command = string.format(
    "%s exec --line %d --column %d",
    md_babel_path, location.line, location.column
  )

  -- TODO: Do we freeze the app with 64KiB or larger docs? https://github.com/md-babel/md-babel.nvim/issues/2
  local handle = io.popen(command, "w")
  handle:write(document_text)
  local output = handle:close()

  if not output then
    vim.api.nvim_err_writeln("Error executing md-babel")
    return
  end

  -- Parse the JSON response
  local json_ok, response = pcall(vim.fn.json_decode, output)
  if not json_ok then
    vim.api.nvim_err_writeln("Failed to parse md-babel output: " .. output)
    return
  end

  md_babel.apply_response(response)
end

---Transforms cmark Source Location (1-based line and column) to nvim's cursor location
function md_babel.cursor_position(source_loc)
  return {
    line: source_loc.line,        -- line is 1-based in both cmark/nvim
    colum: source_loc.column - 1  -- column is 0-based in nvim
  }
end

function md_babel.apply_response(response)
  -- Convert 1-based positions to Neovim's format (1-based lines, 0-based columns)
  local start_line = response.replacementRange.from.line
  local start_col = response.replacementRange.from.column - 1
  local end_line = response.replacementRange.to.line
  local end_col = response.replacementRange.to.column - 1

  -- Of course here, indexing is 0-based: https://neovim.io/doc/user/api.html#nvim_buf_set_text()
  vim.api.nvim_buf_set_text(
    0,
    start_line - 1, start_col,
    end_line - 1, end_col,
    vim.split(response.replacementString, "\n")
  )

  -- Set cursor position (usually to the original position) after the replacement
  vim.api.nvim_win_set_cursor(0, md_babel.cursor_position(response.range.from))
end

return md_babel
