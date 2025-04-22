local module = require("md_babel.module")

---@class Config
---@field md_babel_path string? Path to the md-babel executable.
---@field keymap string? Shortcut to execute the code block at cursor position.
local config = {
  md_babel_path = nil,
  keymap = '<C-CR>' -- Ctrl+Enter
}

local M = {}

M.config = config

---@param args Config?
M.setup = function(args)
  M.config = vim.tbl_deep_extend("force", M.config, args or {})

  -- TODO: Is this pattern normal? Move vim.g.md_babel_executable_path solely into local config?  https://github.com/md-babel/md-babel.nvim/issues/1
  vim.g.md_babel_executable_path = M.config.md_babel_path

  vim.api.nvim_create_user_command('MdBabelExec', function()
                                     M.execute_block_at_point()
  end, {})

  if M.config.keymap then
    vim.keymap.set('n', M.config.keymap, M.execute_block_at_point,
                   {noremap = true, silent = true, desc = "Execute md-babel with code block at cursor"})
  end
end

return M
