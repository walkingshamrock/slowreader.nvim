local M = {}

local function set_cursor(row, col)
  vim.api.nvim_win_set_cursor(0, { row + 1, col })
end

local function keep_cursor_with_margin(scroll_margin)
  local margin = scroll_margin or 0
  local win_height = vim.api.nvim_win_get_height(0)
  local cursor = vim.api.nvim_win_get_cursor(0)
  local top_line = math.max(0, cursor[1] - (win_height - margin))
  vim.fn.winrestview({ topline = top_line + 1 })
end

local function redraw_cursor(row, col, scroll_margin)
  set_cursor(row, col)
  keep_cursor_with_margin(scroll_margin)
  vim.cmd("redraw")
end

local function restore_ui_state(buf, state)
  if not vim.api.nvim_buf_is_valid(buf) then return end

  local function restore_snacks()
    local ok, words = pcall(require, "snacks.words")
    if ok and words and state.snacks_words_enabled_before then
      words.enable()
    end
  end

  restore_snacks()
  for k, v in pairs(state.previous_ui_settings or {}) do
    vim.wo[k] = v
  end
  vim.bo[buf].modifiable = true

  if not state.stop_flag then
    vim.api.nvim_echo({ { "SlowRead complete", "Question" } }, false, {})
  end

  vim.api.nvim_buf_delete(buf, { force = true })
end

local function save_ui_state(state)
  state.previous_ui_settings = {
    number = vim.wo.number,
    relativenumber = vim.wo.relativenumber,
    cursorline = vim.wo.cursorline,
    cursorcolumn = vim.wo.cursorcolumn,
  }
end

local function disable_snacks_words(state)
  local ok, words = pcall(require, "snacks.words")
  if ok and words then
    state.snacks_words_enabled_before = true
    words.disable()
  else
    state.snacks_words_enabled_before = false
  end
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

local function animate_characters(chars, filetype, config, state)
  vim.cmd("enew")
  local buf = vim.api.nvim_get_current_buf()
  vim.bo[buf].filetype = filetype

  save_ui_state(state)

  vim.wo.number = false
  vim.wo.relativenumber = false
  vim.wo.cursorline = false
  vim.wo.cursorcolumn = false
  vim.bo[buf].modifiable = true

  local top = config.top_margin or 0
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.fn["repeat"]({ "" }, top + 1))
  vim.bo[buf].modifiable = false

  local row, col = top, 0
  redraw_cursor(row, col, config.scroll_margin)

  local function feed_next()
    if state.stop_flag or #chars == 0 then
      local delay = state.stop_flag and 0 or (config.final_delay or 0)
      vim.defer_fn(function()
        restore_ui_state(buf, state)
      end, delay)
      return
    end

    local ch = table.remove(chars, 1)

    if ch == "\n" then
      row = row + 1
      col = 0
      vim.bo[buf].modifiable = true
      vim.api.nvim_buf_set_lines(buf, row, row, false, { "" })
      vim.bo[buf].modifiable = false
      redraw_cursor(row, col, config.scroll_margin)
      vim.defer_fn(feed_next, config.delay)
      return
    end

    vim.bo[buf].modifiable = true
    vim.api.nvim_buf_set_text(buf, row, col, row, col, { " " })
    vim.bo[buf].modifiable = false
    col = col + 1
    redraw_cursor(row, col, config.scroll_margin)

    vim.defer_fn(function()
      if state.stop_flag then
        restore_ui_state(buf, state)
        return
      end
      vim.bo[buf].modifiable = true
      vim.api.nvim_buf_set_text(buf, row, col - 1, row, col, { ch })
      vim.bo[buf].modifiable = false
      redraw_cursor(row, col, config.scroll_margin)
      feed_next()
    end, config.delay)
  end

  vim.defer_fn(feed_next, config.initial_delay or 0)
end

function M.run(filename, config, state)
  state.stop_flag = false

  vim.keymap.set("n", config.stop_key, function()
    state.stop_flag = true
    vim.api.nvim_echo({ { "SlowRead interrupted", "WarningMsg" } }, false, {})
  end, { noremap = true, silent = true, desc = "Stop SlowRead" })

  disable_snacks_words(state)

  local chars = collect_characters(filename)
  if not chars then return end

  local filetype = (filename and filename ~= "")
      and (vim.filetype.match({ filename = filename }) or "text")
      or vim.bo.filetype

  animate_characters(chars, filetype, config, state)
end

return M
