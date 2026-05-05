local M = {}

local function log(msg)
  local f = io.open("/tmp/dv_debug.log", "a")
  if f then f:write(msg .. "\n") f:close() end
end

local function build_set_expr(node)
  local chain = {}
  local current = node
  while current do
    table.insert(chain, 1, current)
    current = current.parent
  end

  local root = chain[1]
  local expr = root.name

  for i = 2, #chain do
    local n = chain[i]
    -- array index - no dot or arrow
    if n.name:match("^%[") then
      expr = expr .. n.name
    elseif chain[i-1].is_pointer then
      expr = expr .. "->" .. n.name
    else
      expr = expr .. "." .. n.name
    end
  end

  return expr
end

local function attach_keymaps(buf, win, line_map, frameId, prev_win, session)

  local function do_set(line_num, node, use_input)
    if not node or node.is_complex then
      vim.notify("Use Tab to expand nested struct", vim.log.levels.WARN)
      return
    end

    local set_expr = build_set_expr(node)
    log("set_expr: " .. set_expr)

    local function send_set(value)
      local cur_session = require("dap").session()
      if not cur_session then return end
      local cmd = "-exec set variable " .. set_expr .. " = " .. value
      log("sending: " .. cmd)
      cur_session:request("evaluate", {
        expression = cmd,
        context = "repl",
        frameId = frameId,
      }, function(set_err)
        vim.schedule(function()
          if set_err then
            vim.notify("Error setting " .. set_expr, vim.log.levels.ERROR)
            log("set_err: " .. vim.inspect(set_err))
          else
            node.value = value
            vim.notify(set_expr .. " = " .. value, vim.log.levels.INFO)
          end
        end)
      end)
    end

    if use_input then
      vim.ui.input({
        prompt = set_expr .. " = ",
        default = node.value,
      }, function(input)
        if not input then return end
        send_set(input)
        -- update display
        vim.bo[buf].modifiable = true
        local new_line = string.format("%s  %-30s = %s", node.indent or "", node.name, input)
        vim.api.nvim_buf_set_lines(buf, line_num - 1, line_num, false, { new_line })
        vim.bo[buf].modifiable = false
      end)
    else
      -- inline edit
      vim.bo[buf].modifiable = true
      local line = vim.api.nvim_buf_get_lines(buf, line_num - 1, line_num, false)[1]
      local eq_pos = line:find("=")
      if eq_pos then
        vim.api.nvim_win_set_cursor(win, {line_num, eq_pos + 1})
      end
      vim.cmd("startinsert!")

      vim.keymap.set("i", "<Esc>", function()
        vim.cmd("stopinsert")
        local new_line = vim.api.nvim_buf_get_lines(buf, line_num - 1, line_num, false)[1]
        local new_val = new_line:match("=%s*(.-)%s*$")
        vim.bo[buf].modifiable = false
        if new_val and new_val ~= node.value then
          send_set(new_val)
        end
      end, { buffer = buf, nowait = true })

      vim.keymap.set("i", "jk", function()
        vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "i", false)
      end, { buffer = buf })
    end
  end

  local function close()
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
    if vim.api.nvim_buf_is_valid(buf) then
      vim.api.nvim_buf_delete(buf, { force = true })
    end
    if vim.api.nvim_win_is_valid(prev_win) then
      vim.api.nvim_set_current_win(prev_win)
    end
  end

  local function resize_win()
    local new_line_count = vim.api.nvim_buf_line_count(buf)
    local new_height = math.min(new_line_count + 2, math.floor(vim.o.lines * 0.9))
    local new_row = math.floor((vim.o.lines - new_height) / 2)
    local width = 75
    vim.api.nvim_win_set_config(win, {
      relative  = "editor",
      width     = 75,
      height    = new_height,
      row       = new_row,
     -- col       = math.floor((vim.o.columns - 65) / 2),
      col       = math.floor((vim.o.columns - width) / 2),
    })
    end

  vim.keymap.set("n", "q",     close, { buffer = buf, nowait = true })
  vim.keymap.set("n", "<Esc>", close, { buffer = buf, nowait = true })

  vim.keymap.set("n", "i", function()
    local line_num = vim.api.nvim_win_get_cursor(win)[1]
    local node = line_map[line_num]
    do_set(line_num, node, false)
  end, { buffer = buf, nowait = true })


  vim.keymap.set("n", "A", function()
    local line_num = vim.api.nvim_win_get_cursor(win)[1]
    local node = line_map[line_num]
    do_set(line_num, node, false)
  end, { buffer = buf, nowait = true })


  vim.keymap.set("n", "<CR>", function()
    local line_num = vim.api.nvim_win_get_cursor(win)[1]
    local node = line_map[line_num]
    do_set(line_num, node, true)
  end, { buffer = buf, nowait = true })

  local expanded = {}
  -- Tab to expand nested struct inline
  vim.keymap.set("n", "<Tab>", function()
    local line_num = vim.api.nvim_win_get_cursor(win)[1]
    local node = line_map[line_num]
    if not node or not node.is_complex then return end


    -- if already expanded, collapse it
    if expanded[node] then
      -- find how many lines to remove
      local remove_count = 0
      local next_line = line_num + 1
      while line_map[next_line] and (line_map[next_line].indent or ""):len() > (node.indent or ""):len() do
        remove_count = remove_count + 1
        next_line = next_line + 1
      end
      if remove_count > 0 then
        vim.bo[buf].modifiable = true
        vim.api.nvim_buf_set_lines(buf, line_num, line_num + remove_count, false, {})
        vim.bo[buf].modifiable = false
        -- remove from line_map and shift
        local new_map = {}
        for k, v in pairs(line_map) do
          if k <= line_num then
            new_map[k] = v
          elseif k > line_num + remove_count then
            new_map[k - remove_count] = v
          end
          -- entries between line_num+1 and line_num+remove_count are dropped
        end
        for k in pairs(line_map) do line_map[k] = nil end
        for k, v in pairs(new_map) do line_map[k] = v end
        expanded[node] = nil
      end

      vim.schedule(function()
        resize_win()
      end)
      return
    end
  
    -- not expanded yet, expand it
    expanded[node] = true

    local cur_session = require("dap").session()
    if not cur_session then return end

    cur_session:request("variables", {
      variablesReference = node.variablesReference,
    }, function(err3, child_vars)
      if err3 or not child_vars then return end
      vim.schedule(function()
        local child_lines = {}
        local new_entries = {}
        local child_indent = (node.indent or "") .. "  "

        for _, var in ipairs(child_vars.variables) do
          local is_string = var.type and (
            var.type:find("string") ~= nil or
            var.type:find("char") ~= nil
          )
          local display_val = (var.variablesReference ~= 0 and not is_string) and "{...}" or (var.value or "")
          local child_line = string.format("%s  %-28s = %s", child_indent, var.name, display_val)
          --local child_line = string.format("%s  %-28s = %s", child_indent, var.name, (var.variablesReference ~= 0) and "{...}" or (var.value or ""))
          table.insert(child_lines, child_line)
          local child_node = {
            name             = var.name,
            value            = var.value,
            evaluateName     = var.evaluateName,
            type             = var.type,
            variablesReference = var.variablesReference,
            is_complex       = var.variablesReference ~= 0,
            is_pointer       = var.type and var.type:find("%*") ~= nil,
            indent           = child_indent,
            parent           = node,  -- link to parent
          }
          table.insert(new_entries, child_node)
        end

        vim.bo[buf].modifiable = true
        vim.api.nvim_buf_set_lines(buf, line_num, line_num, false, child_lines)
        vim.bo[buf].modifiable = false

        -- update line_map
        local shift = #child_lines
        local new_map = {}
        for k, v in pairs(line_map) do
          if k > line_num then
            new_map[k + shift] = v
          else
            new_map[k] = v
          end
        end
        for i, child_node in ipairs(new_entries) do
          new_map[line_num + i] = child_node
        end
        for k in pairs(line_map) do line_map[k] = nil end
        for k, v in pairs(new_map) do line_map[k] = v end

        -- highlights
        for i, child_node in ipairs(new_entries) do
          local li = line_num + i - 1
          if not child_node.is_complex then
            local child_line = child_lines[i]
            local eq = child_line:find("=")
            if eq then
              vim.api.nvim_buf_add_highlight(buf, -1, "Identifier", li, 0, eq - 1)
              vim.api.nvim_buf_add_highlight(buf, -1, "String", li, eq, -1)
            end
          else
            vim.api.nvim_buf_add_highlight(buf, -1, "Identifier", li, 0, -1)
          end
        end

      -- after expanding, resize window
      vim.schedule(function()
        resize_win()
      end)
      end)
    end)
  end, { buffer = buf, nowait = true })
end

local function open_window(expr, type_str, variables, frameId, prev_win, session, root_node)
  vim.api.nvim_set_hl(0, "Cursor", { fg = "#000000", bg = "#FF00FF" })
  vim.api.nvim_set_hl(0, "CursorIM", { fg = "#000000", bg = "#FF00FF" })
  vim.opt.guicursor = "n-v-c:block,i-ci-ve:ver25,r-cr:hor20,o:hor50,a:Cursor/lCursor"
  local lines = {}
  local line_map = {}

  table.insert(lines, expr .. ": " .. (type_str or ""))
  table.insert(lines, string.rep("─", 63))

  for _, var in ipairs(variables) do
    local is_string = var.type and (
      var.type:find("string") ~= nil or
      var.type:find("char") ~= nil
    ) 
    local display_value = (var.variablesReference ~= 0 and not is_string) and "{...}" or (var.value or "")
    local line_text = string.format("  %-30s = %s", var.name, display_value)
    table.insert(lines, line_text)
    local is_string = var.type and (
        var.type:find("string") ~= nil or
        var.type:find("char") ~= nil
    )
    local node = {
      name               = var.name,
      value              = var.value,
      evaluateName       = var.evaluateName,
      type               = var.type,
      variablesReference = var.variablesReference,
      -- treat strings as simple even though they have variablesReference
      is_complex         = var.variablesReference ~= 0 and not is_string,
      is_pointer         = var.type and var.type:find("%*") ~= nil,
      indent             = "",
      parent             = root_node,  -- link to root
    }
    line_map[#lines] = node
  end

  table.insert(lines, string.rep("─", 63))
  table.insert(lines, "  i/CR edit    Tab expand    q close")

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
  vim.bo[buf].buftype = "nofile"

  local width = 75
  local height = math.min(#lines + 2, 55)
  local win = vim.api.nvim_open_win(buf, true, {
    relative   = "editor",
    width      = width,
    height     = height,
    row        = math.floor((vim.o.lines - height) / 2),
    col        = math.floor((vim.o.columns - width) / 2),
    style      = "minimal",
    border     = "rounded",
    title      = " " .. expr .. " ",
    title_pos  = "center",
  })

  -- highlights
  vim.api.nvim_buf_add_highlight(buf, -1, "Title",   0,          0, -1)
  vim.api.nvim_buf_add_highlight(buf, -1, "Comment", 1,          0, -1)
  vim.api.nvim_buf_add_highlight(buf, -1, "Comment", #lines - 2, 0, -1)
  vim.api.nvim_buf_add_highlight(buf, -1, "Comment", #lines - 1, 0, -1)
  for i, node in pairs(line_map) do
    if node.is_complex then
      vim.api.nvim_buf_add_highlight(buf, -1, "Identifier", i - 1, 0, -1)
    else
      local eq = lines[i] and lines[i]:find("=")
      if eq then
        vim.api.nvim_buf_add_highlight(buf, -1, "Identifier", i - 1, 0, eq - 1)
        vim.api.nvim_buf_add_highlight(buf, -1, "String",     i - 1, eq, -1)
      end
    end
  end

  attach_keymaps(buf, win, line_map, frameId, prev_win, session)
end

function M.open()
  local session = require("dap").session()
  if not session then
    vim.notify("No active debug session", vim.log.levels.WARN)
    return
  end

  local expr     = vim.fn.expand("<cword>")
  local frameId  = session.current_frame and session.current_frame.id
  local prev_win = vim.api.nvim_get_current_win()

  session:request("evaluate", {
    expression = expr,
    context    = "hover",
    frameId    = frameId,
  }, function(err, response)
    if err or not response then
      vim.notify("Could not evaluate: " .. expr, vim.log.levels.ERROR)
      return
    end

    local varRef = response.variablesReference

    -- simple value
    if varRef == 0 then
      vim.schedule(function()
        local lines = {
          expr .. ": " .. (response.type or ""),
          string.rep("─", 63),
          string.format("  %-30s = %s", expr, response.result),
          string.rep("─", 63),
          "  i/CR edit    q close",
        }
        local root_node = {
          name       = expr,
          value      = response.result,
          type       = response.type or "",
          is_pointer = response.type and response.type:find("%*") ~= nil,
          parent     = nil,
        }
        local line_map = {
          [3] = {
            name       = expr,
            value      = response.result,
            evaluateName = expr,
            type       = response.type or "",
            is_complex = false,
            is_pointer = false,
            indent     = "",
            parent     = nil,
          }
        }
        local buf = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
        vim.bo[buf].modifiable = false
        vim.bo[buf].buftype    = "nofile"
        local width  = 75
        local height = #lines + 2
        local win = vim.api.nvim_open_win(buf, true, {
          relative  = "editor",
          width     = width,
          height    = height,
          row       = math.floor((vim.o.lines - height) / 2),
          col       = math.floor((vim.o.columns - width) / 2),
          style     = "minimal",
          border    = "rounded",
          title     = " " .. expr .. " ",
          title_pos = "center",
        })
        vim.api.nvim_buf_add_highlight(buf, -1, "Title",      0, 0, -1)
        vim.api.nvim_buf_add_highlight(buf, -1, "Comment",    1, 0, -1)
        vim.api.nvim_buf_add_highlight(buf, -1, "Identifier", 2, 0, 32)
        vim.api.nvim_buf_add_highlight(buf, -1, "String",     2, 32, -1)
        vim.api.nvim_buf_add_highlight(buf, -1, "Comment",    3, 0, -1)
        vim.api.nvim_buf_add_highlight(buf, -1, "Comment",    4, 0, -1)
        attach_keymaps(buf, win, line_map, frameId, prev_win, session)
      end)
      return
    end

    -- struct/complex
    session:request("variables", {
      variablesReference = varRef,
    }, function(err2, vars_response)
      if err2 or not vars_response then
        vim.notify("Could not get variables", vim.log.levels.ERROR)
        return
      end
      vim.schedule(function()
        -- create root node
        local root_node = {
          name       = expr,
          type       = response.type,
          is_pointer = response.type and response.type:find("%*") ~= nil,
          parent     = nil,
        }
        open_window(expr, response.type, vars_response.variables, frameId, prev_win, session, root_node)
      end)
    end)
  end)
end

return M
