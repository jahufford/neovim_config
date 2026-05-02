local function log(msg)
  local f = io.open("/tmp/dv_debug.log", "a")
  if f then f:write(msg .. "\n") f:close() end
end

local M = {}

local function create_window(title, lines, line_map, prev_win, buf_existing)
  local buf = buf_existing or vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
  vim.bo[buf].buftype = "nofile"

  local width = 65
  local height = math.min(#lines + 2, 35)
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = math.floor((vim.o.lines - height) / 2),
    col = math.floor((vim.o.columns - width) / 2),
    style = "minimal",
    border = "rounded",
    title = " " .. title .. " ",
    title_pos = "center",
  })

  -- highlights
  vim.api.nvim_buf_add_highlight(buf, -1, "Title", 0, 0, -1)
  vim.api.nvim_buf_add_highlight(buf, -1, "Comment", 1, 0, -1)
  vim.api.nvim_buf_add_highlight(buf, -1, "Comment", #lines - 2, 0, -1)
  vim.api.nvim_buf_add_highlight(buf, -1, "Comment", #lines - 1, 0, -1)
  for i, node in pairs(line_map) do
    if node.is_complex then
      vim.api.nvim_buf_add_highlight(buf, -1, "Comment", i - 1, 0, -1)
    else
      local eq = lines[i] and lines[i]:find("=")
      if eq then
        vim.api.nvim_buf_add_highlight(buf, -1, "Identifier", i - 1, 0, eq - 1)
        vim.api.nvim_buf_add_highlight(buf, -1, "String", i - 1, eq, -1)
      end
    end
  end

  return buf, win
end

local function build_lines(expr, type_str, variables, indent)
  indent = indent or ""
  local lines = {}
  local line_map = {}

  if indent == "" then
    table.insert(lines, expr .. ": " .. (type_str or ""))
    table.insert(lines, string.rep("─", 63))
  end

  for _, var in ipairs(variables) do
    local line_text = string.format("%s  %-30s = %s", indent, var.name, var.value or "{...}")
    table.insert(lines, line_text)
    local node = {
      name = var.name,
      value = var.value,
      evaluateName = var.evaluateName,
      type = var.type,
      variablesReference = var.variablesReference,
      is_complex = var.variablesReference ~= 0,
      indent = indent,
    }
    line_map[#lines] = node
  end

  return lines, line_map
end

local function open_editor(expr, frameId, prev_win, session)
  session:request("evaluate", {
    expression = expr,
    context = "hover",
    frameId = frameId,
  }, function(err, response)
    if err or not response then
      vim.notify("Could not evaluate: " .. expr, vim.log.levels.ERROR)
      return
    end

    local varRef = response.variablesReference

    -- simple value, no children
    if varRef == 0 then
      vim.schedule(function()
        local lines = {
          expr .. ": " .. (response.type or ""),
          string.rep("─", 63),
          string.format("  %-30s = %s", expr, response.result),
          string.rep("─", 63),
          "  i/CR edit    q close",
        }
        local line_map = {
          [3] = {
            name = expr,
            value = response.result,
            evaluateName = expr,
            type = response.type or "",
            is_complex = false,
          }
        }
        local buf, win = create_window(expr, lines, line_map, prev_win)
        attach_keymaps(buf, win, lines, line_map, frameId, prev_win, expr, response.type or "", session)
      end)
      return
    end

    -- struct/complex — fetch children
    session:request("variables", {
      variablesReference = varRef,
    }, function(err2, vars_response)
      if err2 or not vars_response then
        vim.notify("Could not get variables", vim.log.levels.ERROR)
        return
      end

      vim.schedule(function()
        local lines, line_map = build_lines(expr, response.type, vars_response.variables)
        table.insert(lines, string.rep("─", 63))
        table.insert(lines, "  i/CR edit    Tab expand    q close")
        local buf, win = create_window(expr, lines, line_map, prev_win)
        attach_keymaps(buf, win, lines, line_map, frameId, prev_win, expr, response.type, session)
      end)
    end)
  end)
end

-- forward declare so attach_keymaps can reference open_editor
function attach_keymaps(buf, win, lines, line_map, frameId, prev_win, expr, type_str, session)

  local function do_edit(line_num, node, use_input)
    if not node or node.is_complex then
      vim.notify("Use Tab to expand nested struct", vim.log.levels.WARN)
      return
    end

    if use_input then
      vim.ui.input({
        prompt = node.name .. " (" .. node.type .. ") = ",
        default = node.value,
      }, function(input)
        if not input then return end
        local cur_session = require("dap").session()
        if not cur_session then return end
        local clean_expr = node.evaluateName:gsub("%(", ""):gsub("%)", "")
        log("evaluateName: " .. (node.evaluateName or "nil"))
        log("sending: " .. cmd)
        cur_session:request("evaluate", {
          expression = "-exec set variable " .. clean_expr .. " = " .. input,
          context = "repl",
          frameId = frameId,
        }, function(set_err)
          vim.schedule(function()
            log("evaluateName: " .. (node.evaluateName or "nil"))
            log("set_err: " .. vim.inspect(set_err))
            if set_err then
              vim.notify("Error setting " .. node.name, vim.log.levels.ERROR)
            else
              node.value = input
              vim.bo[buf].modifiable = true
              local new_line = string.format("%s  %-30s = %s", node.indent or "", node.name, input)
              vim.api.nvim_buf_set_lines(buf, line_num - 1, line_num, false, { new_line })
              vim.bo[buf].modifiable = false
              vim.notify(node.name .. " = " .. input, vim.log.levels.INFO)
            end
          end)
        end)
      end)
    else
      -- inline edit with i
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
          local cur_session = require("dap").session()
          if not cur_session then return end
          local clean_expr = node.evaluateName:gsub("%(", ""):gsub("%)", "")
          -- local cmd = "-exec set variable " .. clean_expr .. " = " .. new_val
          --local cmd = "-exec set variable " .. node.evaluateName .. " = " .. new_val

--          local function fix_expr(expr)
--            -- find the innermost (Type *)0xADDR)-> pattern
--            -- by finding the first -> which indicates pointer dereference
--            local arrow_pos = expr:find("%)%->")
--            if not arrow_pos then
--              return expr  -- no pointer dereference, return as-is
--            end
--            
--            -- find the matching open paren for the pointer cast
--            -- work backwards from arrow_pos to find (Type *)0xADDR
--            local inner = expr:sub(1, arrow_pos + 1)  -- up to and including ->
--            
--            -- find the address
--            local addr = inner:match("(0x%x+)%)")
--            if not addr then return expr end
--            
--            -- find the type - everything between last ( and *) before the address  
--            local type_str = inner:match("%((.-)%s*%*)%s*" .. addr)
--            if not type_str then return expr end
--            
--            -- get everything after the ->
--            local after_arrow = expr:sub(arrow_pos + 3)  -- skip )->
--            
--            -- strip all remaining parens keeping field access and array indexing
--            after_arrow = after_arrow:gsub("^%(+", "")  -- leading parens
--            after_arrow = after_arrow:gsub("%)$", "")   -- trailing parens  
--            after_arrow = after_arrow:gsub("%)%.", ".")  -- ).  -> .
--            after_arrow = after_arrow:gsub("%(", "")    -- remaining (
--            
--            return string.format("(*(%s *)%s).%s", type_str, addr, after_arrow)
--          end
            local function fix_expr(expr)
              -- find the address by scanning for "0x"
              local addr_start = nil
              for i = 1, #expr - 1 do
                if expr:sub(i, i+1) == "0x" then
                  addr_start = i
                  break
                end
              end
              if not addr_start then return expr end
              
              -- find end of address (hex digits after 0x)
              local addr_end = addr_start + 1
              while addr_end <= #expr and expr:sub(addr_end+1, addr_end+1):match("[%x]") do
                addr_end = addr_end + 1
              end
              local addr = expr:sub(addr_start, addr_end)
              
              -- find ")->" after address
              local arrow = expr:find(")->", addr_end, true)
              if not arrow then return expr end
              
              -- find type: scan backwards from addr_start for "("
              -- we want the content between the ( immediately before the type and the *
              local star_pos = nil
              for i = addr_start - 1, 1, -1 do
                if expr:sub(i, i) == "*" then
                  star_pos = i
                  break
                end
              end
              if not star_pos then return expr end
              
              -- find the ( before the type
              local open_pos = nil
              for i = star_pos - 1, 1, -1 do
                if expr:sub(i, i) == "(" then
                  open_pos = i
                  break
                end
              end
              if not open_pos then return expr end
              
              local type_str = expr:sub(open_pos + 1, star_pos - 1):gsub("^%s+", ""):gsub("%s+$", "")
              
              -- get fields after )->
              local after = expr:sub(arrow + 2)
              -- clean up parens
              local result = {}
              local depth = 0
              for i = 1, #after do
                local c = after:sub(i, i)
                if c == "(" then
                  depth = depth + 1
                elseif c == ")" then
                  depth = depth - 1
                  if depth >= 0 and after:sub(i+1, i+1) == "." then
                    table.insert(result, ".")
                    -- skip the . too
                  end
                else
                  table.insert(result, c)
                end
              end
              local clean_after = table.concat(result)
              -- remove leading .
              clean_after = clean_after:gsub("^%.", "")
              
              log("type: [" .. type_str .. "] addr: [" .. addr .. "] after: [" .. clean_after .. "]")
              return string.format("(*(%s *)%s).%s", type_str, addr, clean_after)
            end
local type_str, addr = node.evaluateName:match("%(%((.-)%s*%*%)%s*(0x%x+)%)")
log("type_str: " .. tostring(type_str))
log("addr: " .. tostring(addr))
local rest = node.evaluateName:match("0x%x+%)->(.+)$")
log("rest: " .. tostring(rest))
log("fix result: " .. fix_expr(node.evaluateName))
          local cmd = "-exec set variable " .. fix_expr(node.evaluateName) .. " = " .. new_val
          log("evaluateName: " .. (node.evaluateName or "nil"))
          log("sending: " .. cmd)
          cur_session:request("evaluate", {
            expression = "-exec set variable " .. clean_expr .. " = " .. new_val,
            context = "repl",
            frameId = frameId,
          }, function(set_err)
            vim.schedule(function()
              log("evaluateName: " .. (node.evaluateName or "nil"))
              log("set_err: " .. vim.inspect(set_err))
              if set_err then
                vim.notify("Error setting " .. node.name, vim.log.levels.ERROR)
                vim.bo[buf].modifiable = true
                local orig = string.format("%s  %-30s = %s", node.indent or "", node.name, node.value)
                vim.api.nvim_buf_set_lines(buf, line_num - 1, line_num, false, { orig })
                vim.bo[buf].modifiable = false
              else
                node.value = new_val
                vim.notify(node.name .. " = " .. new_val, vim.log.levels.INFO)
              end
            end)
          end)
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

  vim.keymap.set("n", "q", close, { buffer = buf, nowait = true })
  vim.keymap.set("n", "<Esc>", close, { buffer = buf, nowait = true })

  vim.keymap.set("n", "i", function()
    local line_num = vim.api.nvim_win_get_cursor(win)[1]
    local node = line_map[line_num]
    do_edit(line_num, node, false)
  end, { buffer = buf, nowait = true })

  vim.keymap.set("n", "<CR>", function()
    local line_num = vim.api.nvim_win_get_cursor(win)[1]
    local node = line_map[line_num]
    do_edit(line_num, node, true)
  end, { buffer = buf, nowait = true })

  -- Tab to expand nested struct inline
  vim.keymap.set("n", "<Tab>", function()
    local line_num = vim.api.nvim_win_get_cursor(win)[1]
    local node = line_map[line_num]
    if not node or not node.is_complex then return end

    local cur_session = require("dap").session()
    if not cur_session then return end

    cur_session:request("variables", {
      variablesReference = node.variablesReference,
    }, function(err3, child_vars)
      if err3 or not child_vars then return end
      vim.schedule(function()
        -- insert children after current line
        local child_lines = {}
        local new_entries = {}
        local child_indent = (node.indent or "") .. "  "
        for _, var in ipairs(child_vars.variables) do
          local child_line = string.format("%s  %-28s = %s", child_indent, var.name, var.value or "{...}")
          table.insert(child_lines, child_line)
          local child_node = {
            name = var.name,
            value = var.value,
            evaluateName = var.evaluateName,
            type = var.type,
            variablesReference = var.variablesReference,
            is_complex = var.variablesReference ~= 0,
            indent = child_indent,
          }
          table.insert(new_entries, child_node)
        end

        -- insert into buffer
        vim.bo[buf].modifiable = true
        vim.api.nvim_buf_set_lines(buf, line_num, line_num, false, child_lines)
        vim.bo[buf].modifiable = false

        -- update line_map — shift all entries after line_num
        local shift = #child_lines
        local new_map = {}
        for k, v in pairs(line_map) do
          if k > line_num then
            new_map[k + shift] = v
          else
            new_map[k] = v
          end
        end
        -- add new children
        for i, child_node in ipairs(new_entries) do
          new_map[line_num + i] = child_node
        end
        -- replace line_map contents
        for k in pairs(line_map) do line_map[k] = nil end
        for k, v in pairs(new_map) do line_map[k] = v end

        -- re-highlight new lines
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
            vim.api.nvim_buf_add_highlight(buf, -1, "Comment", li, 0, -1)
          end
        end
      end)
    end)
  end, { buffer = buf, nowait = true })
end

function M.open()
  local session = require("dap").session()
  if not session then
    vim.notify("No active debug session", vim.log.levels.WARN)
    return
  end

  local expr = vim.fn.expand("<cword>")
  local frameId = session.current_frame and session.current_frame.id
  local prev_win = vim.api.nvim_get_current_win()

  open_editor(expr, frameId, prev_win, session)
end

return M
