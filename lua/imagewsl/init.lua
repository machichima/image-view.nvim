local M = {} -- M stands for module, a naming convention

local create_popup = function(img_path)
  local function has_two_panes()
    local panes = tonumber(vim.fn.system("tmux display-message -p '#{window_panes}'"))
    return panes == 2
  end

  if has_two_panes() then
    vim.cmd("!tmux select-pane -l")
    print("There are 2 panes in the current window")
  else
    vim.cmd("!tmux split-window -hf")
    print("The number of panes is not 2")
  end

  vim.cmd('!tmux send-keys -t 1 "imgcat ' .. img_path .. '" Enter')
end

function M.setup()
  print("start")
  -- local client = require("obsidian").get_client()

  local query = vim.treesitter.query.parse("markdown_inline", "(image (link_destination) @url) @image")

  local get_node_at_cursor = function()
    -- print(client.current_workspace.path)

    local cursor_row, cursor_col = unpack(vim.api.nvim_win_get_cursor(0))

    local buf = vim.api.nvim_get_current_buf()
    local parser = vim.treesitter.get_parser(buf, "markdown_inline")
    local tree = parser:parse()[1]:root()

    local has_img = false
    local url = nil

    for id, node in query:iter_captures(tree, 0) do
      print("capture something")
      local name = query.captures[id]
      local value = vim.treesitter.get_node_text(node, buf)

      if name == "image" then
        local start_row, start_col, end_row, end_col = node:range()

        print("element at: ", start_row, start_col, end_row, end_col)
        print("cursor at: ", cursor_row, cursor_col)

        if cursor_row == start_row + 1 and cursor_col >= start_col and cursor_col <= end_col then
          has_img = true
        end
      elseif has_img and name == "url" then
        url = value
        print("name: ", name)
        print("value: ", value)
        create_popup(url)
      end
    end
  end

  vim.keymap.set("n", "<leader>i", get_node_at_cursor, {})
end

return M
