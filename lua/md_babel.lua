local module = require("md_babel.module")

---@class Config
---@field md_babel_path string? Path to the md-babel executable.
---@field keymap string? Shortcut to execute the code block at cursor position.
local config = {
  md_babel_path = nil,
  keymap = '<C-CR>' -- Ctrl+Enter
}

local M = {}

---@param opts Config?
M.setup = function(opts)
  opts = opts or config

  if not opts.md_babel_path then
    error "'md_babel_path' value required"
  end

  -- TODO: Is this pattern normal? Move vim.g.md_babel_executable_path solely into local config?  https://github.com/md-babel/md-babel.nvim/issues/1
  vim.g.md_babel_executable_path = opts.md_babel_path

  vim.api.nvim_create_user_command('MdBabelExec', module.execute_block_at_point, {})

  if opts.keymap then
    vim.keymap.set('n', opts.keymap, module.execute_block_at_point,
                   {noremap = true, silent = true, desc = "Execute md-babel with code block at cursor"})
  end
end

M.execute_block_at_point = module.execute_block_at_point

return M
