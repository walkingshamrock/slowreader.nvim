-- slowreader.insert.lua (disable nvim-cmp during animation)
local M = {}

local function restore_ui_state(buf, state)
  if not vim.api.nvim_buf_is_valid(buf) then return end
  for k, v in pairs(state.previous_ui_settings or {}) do
    vim.wo[k] = v
  end
  vim.bo[buf].modifiable = true
  vim.api.nvim_buf_delete(buf, { force = true })
end

local function collect_characters_from_lines(lines)
  local chars = {}
  for _, line in ipairs(lines) do
    for c in line:gmatch(".") do
      table.insert(chars, c)
    end
    table.insert(chars, "\n")
  end
  return chars
end

local function load_lines_from_file(filename)
  local lines = {}
  local f, err = io.open(filename, "r")
  if not f then
    vim.api.nvim_err_writeln("[SlowInsert] Cannot open file: " .. filename .. " (" .. err .. ")")
    return nil
  end
  for line in f:lines() do
    table.insert(lines, line)
  end
  f:close()
  return lines
end

local function keep_cursor_within_scroll_margin(scroll_margin)
  local win_height = vim.api.nvim_win_get_height(0)
  local cursor = vim.api.nvim_win_get_cursor(0)
  local target_top_line = math.max(0, cursor[1] - (win_height - scroll_margin))
  vim.fn.winrestview({ topline = target_top_line + 1 })
end

local function start_animation(buf, config, state, chars, row, col)
  local function feed_next()
    if state.stop_flag or #chars == 0 then
      vim.defer_fn(function()
        restore_ui_state(buf, state)
      end, config.final_delay or 0)
      return
    end

    local ch = table.remove(chars, 1)

    if ch == "\n" then
      row = row + 1
      col = 0
      vim.bo[buf].modifiable = true
      vim.api.nvim_buf_set_lines(buf, row, row, false, { "" })
      vim.bo[buf].modifiable = false
    else
      vim.bo[buf].modifiable = true
      vim.api.nvim_buf_set_text(buf, row, col, row, col, { ch })
      vim.bo[buf].modifiable = false
      col = col + 1
    end

    vim.api.nvim_win_set_cursor(0, { row + 1, col })
    keep_cursor_within_scroll_margin(config.scroll_margin or 5)

    vim.defer_fn(feed_next, config.delay)
  end

  feed_next()
end

function M.run(filename, config, state, override_lines)
  state.stop_flag = false

  state.previous_ui_settings = {
    number = vim.wo.number,
    relativenumber = vim.wo.relativenumber,
    cursorline = vim.wo.cursorline,
    cursorcolumn = vim.wo.cursorcolumn,
  }

  local filetype = "text"
  if filename and filename ~= "" then
    filetype = vim.filetype.match({ filename = filename }) or "text"
  else
    filetype = vim.bo.filetype
    if not filetype or filetype == "" then
      filetype = "text"
    end
  end

  vim.cmd("enew")
  local buf = vim.api.nvim_get_current_buf()
  vim.bo[buf].filetype = filetype
  vim.bo[buf].modifiable = true

  -- Disable nvim-cmp for this buffer
  local ok_cmp, cmp = pcall(require, "cmp")
  if ok_cmp and cmp and cmp.setup then
    cmp.setup.buffer({ enabled = false })
  end

  vim.wo.number = false
  vim.wo.relativenumber = false
  vim.wo.cursorline = false
  vim.wo.cursorcolumn = false

  local top = config.top_margin or 0
  local padding = {}
  for _ = 1, top + 1 do
    table.insert(padding, "")
  end
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, padding)

  local row, col = top, 0
  vim.api.nvim_win_set_cursor(0, { row + 1, col })
  keep_cursor_within_scroll_margin(config.scroll_margin or 5)
  vim.cmd("startinsert")

  vim.keymap.set("i", config.stop_key, function()
    state.stop_flag = true
    vim.api.nvim_input("<Esc>")
    vim.api.nvim_echo({ { "SlowInsert stopped", "WarningMsg" } }, false, {})
    restore_ui_state(buf, state)
  end, { noremap = true, silent = true, buffer = buf })

  local input_lines = {}
  if override_lines then
    input_lines = override_lines
  elseif filename and filename ~= "" then
    input_lines = load_lines_from_file(filename) or {}
  end

  local chars = collect_characters_from_lines(input_lines)
  vim.defer_fn(function()
    start_animation(buf, config, state, chars, row, col)
  end, config.initial_delay or 0)

  vim.api.nvim_echo({ { "[SlowInsert started - animating]", "ModeMsg" } }, false, {})
end

return M