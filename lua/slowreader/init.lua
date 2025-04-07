local M = {}

M.version = "0.1.0"

M.config = {
  auto_disable_plugins = false,
  delay = 200, -- milliseconds per character
  stop_key = "<Esc>", -- Key to stop the animation
  initial_delay = 0, -- Initial delay before animation starts
}

function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", M.config, opts or {})
end

local state = {
  stop_flag = false,
  snacks_words_enabled_before = true,
  previous_ui_settings = {},
}

local function setup_escape_interrupt()
  vim.keymap.set("n", M.config.stop_key, function()
    state.stop_flag = true
    vim.api.nvim_echo({ { "SlowRead interrupted", "WarningMsg" } }, false, {})
  end, { noremap = true, silent = true, desc = "Stop SlowRead" })
end

local function disable_snacks_words()
  local ok, words = pcall(require, "snacks.words")
  if ok and words then
    state.snacks_words_enabled_before = true
    words.disable()
  else
    state.snacks_words_enabled_before = false
  end
end

local function restore_snacks_words()
  local ok, words = pcall(require, "snacks.words")
  if ok and words and state.snacks_words_enabled_before then
    words.enable()
  end
end

local function restore_ui_state(buf)
  if not vim.api.nvim_buf_is_valid(buf) then
    return
  end

  restore_snacks_words()
  for setting, value in pairs(state.previous_ui_settings) do
    vim.wo[setting] = value
  end
  vim.bo[buf].modifiable = true
end

local function save_ui_state()
  state.previous_ui_settings = {
    number = vim.wo.number,
    relativenumber = vim.wo.relativenumber,
    cursorline = vim.wo.cursorline,
    cursorcolumn = vim.wo.cursorcolumn,
  }
end

local function collect_characters(filename)
  local lines = {}

  if filename and filename ~= "" then
    local f, err = io.open(filename, "r")
    if not f then
      vim.api.nvim_err_writeln("Cannot open file: " .. filename .. " (" .. err .. ")")
      return nil
    end
    for line in f:lines() do
      table.insert(lines, line .. " ")
    end
    f:close()
  else
    for _, line in ipairs(vim.api.nvim_buf_get_lines(0, 0, -1, false)) do
      table.insert(lines, line .. " ")
    end
  end

  local chars = {}
  for _, line in ipairs(lines) do
    for c in line:gmatch(".") do
      table.insert(chars, c)
    end
    table.insert(chars, "\n")
  end

  return chars
end

local function animate_characters(chars, filetype)
  vim.cmd("enew")
  local buf = vim.api.nvim_get_current_buf()
  vim.bo[buf].filetype = filetype

  save_ui_state()

  vim.wo.number = false
  vim.wo.relativenumber = false
  vim.wo.cursorline = false
  vim.wo.cursorcolumn = false
  vim.bo[buf].modifiable = true -- Ensure the buffer is modifiable initially

  vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "" })

  vim.bo[buf].modifiable = false -- Set the buffer to non-modifiable after initial setup

  local row, col = 0, 0

  local function feed_next()
    if state.stop_flag or #chars == 0 then
      restore_ui_state(buf)
      return
    end

    local ch = table.remove(chars, 1)

    if ch == "\n" then
      row = row + 1
      col = 0
      vim.bo[buf].modifiable = true -- Temporarily make the buffer modifiable
      vim.api.nvim_buf_set_lines(buf, row, row, false, { "" })
      vim.bo[buf].modifiable = false -- Restore non-modifiable state
      vim.cmd("redraw")
      vim.defer_fn(feed_next, M.config.delay)
      return
    end

    vim.bo[buf].modifiable = true -- Temporarily make the buffer modifiable
    vim.api.nvim_buf_set_text(buf, row, col, row, col, { " " })
    vim.bo[buf].modifiable = false -- Restore non-modifiable state
    col = col + 1
    vim.api.nvim_win_set_cursor(0, { row + 1, col })
    vim.cmd("redraw")

    vim.defer_fn(function()
      if state.stop_flag then
        restore_ui_state(buf)
        return
      end
      vim.bo[buf].modifiable = true -- Temporarily make the buffer modifiable
      vim.api.nvim_buf_set_text(buf, row, col - 1, row, col, { ch })
      vim.bo[buf].modifiable = false -- Restore non-modifiable state
      vim.api.nvim_win_set_cursor(0, { row + 1, col })
      vim.cmd("redraw")
      feed_next()
    end, M.config.delay)
  end

  vim.defer_fn(feed_next, M.config.initial_delay or 0) -- Add initial delay before starting animation
end

local function determine_filetype(filename)
  if filename and filename ~= "" then
    return vim.filetype.match({ filename = filename }) or "text"
  else
    return vim.bo.filetype
  end
end

local function slow_read(filename)
  state.stop_flag = false
  setup_escape_interrupt()
  disable_snacks_words()

  local chars = collect_characters(filename)
  if not chars then
    return
  end

  local ft = determine_filetype(filename)
  animate_characters(chars, ft)
end

function M.slowread_cmd(opts)
  slow_read(opts.args)
end

vim.api.nvim_create_user_command("SlowRead", M.slowread_cmd, { nargs = "?" })

return M