-- slowreader/init.lua
local M = {}

M.version = "0.4.0-dev"

M.config = {
  delay = 200,
  stop_key = "<Esc>",
  initial_delay = 0,
  final_delay = 0,
  scroll_margin = 5,
  top_margin = 0,
}

M.state = {
  stop_flag = false,
  snacks_words_enabled_before = true,
  previous_ui_settings = {},
}

function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", M.config, opts or {})
  M.setup_commands()
end

function M.setup_commands()
  vim.api.nvim_create_user_command("SlowRead", function(opts)
    require("slowreader.read").run(opts.args, M.config, M.state)
  end, {
    nargs = "?",
    complete = "file",
 })

  vim.api.nvim_create_user_command("SlowInsert", function(opts)
    if opts.args == "" then
      local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
      require("slowreader.insert").run(nil, M.config, M.state, lines)
    else
      require("slowreader.insert").run(opts.args, M.config, M.state)
    end
  end, {
    nargs = "?",
    complete = "file",
  })
end

return M
