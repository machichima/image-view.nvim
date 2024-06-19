local M = {} -- M stands for module, a naming convention

---@type config
M.config = {
  opts = {
    open_type = "explorer",
    -- option:
    -- 1. "explorer": by Windows picture / tmux
    -- 2. "tmux"
    -- 3. "wsl": use `open` command
  },
}

local create_popup = function(img_path)
  if M.config.opts.open_type == "explorer" then
    vim.cmd("!wsl-open '" .. img_path .. "'")
    print("use windows explorer")
  end

  if M.config.opts.open_type == "wsl" then
    vim.cmd("!open '" .. img_path .. "'")
    print("use wsl open")
  end

  if M.config.opts.open_type == "tmux" then
    local function has_two_panes()
      local panes = tonumber(vim.fn.system("tmux display-message -p '#{window_panes}'"))
      return panes == 2
    end

    if has_two_panes() then
      vim.cmd("!tmux select-pane -l")
      print("There are 2 panes in the current window")
    else
      vim.cmd("!tmux split-window -hf -d")
      print("The number of panes is not 2")
    end

    -- vim.fn.setreg("+", img_path)
    vim.cmd('!tmux send-keys -t 1 "imgcat ' .. img_path .. '" Enter')
  end
end

---@param params config
function M.setup(params)
  -- set up user config
  M.config = vim.tbl_deep_extend("force", {}, M.config, params)

  local client = require("obsidian").get_client()

  local in_obsidian = false -- client.path_is_note(vim.fn.expand("%:p"), client.current_workspace)
  print(client.current_workspace.path)

  local get_node_at_cursor = function()
    if string.find(vim.fn.expand("%:p"), tostring(client.current_workspace.path)) then
      in_obsidian = true
    end

    print("in obsidian? ", in_obsidian)

    local query = nil
    if in_obsidian then
      -- For obsidian notes (with incomplete image path)
      query = vim.treesitter.query.parse(
        "markdown_inline",
        "(image (image_description(shortcut_link(link_text) @url))) @image"
      )
    else
      -- For other markdown note (with full image path)
      query = vim.treesitter.query.parse("markdown_inline", "(image (link_destination) @url) @image")
    end

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
        print(client.current_workspace.path, value)
        if in_obsidian then
          -- For obsidian notes (with incomplete image path)
          local workspace_path = tostring(client.current_workspace.path)
          local attachments_folder = client.opts.attachments.img_folder
          url = workspace_path .. "/" .. attachments_folder .. "/" .. value
        else
          -- For other markdown note (with full image path)
          url = value
        end
        print("name: ", name)
        print("value: ", value)
        print("url: ", url)
        create_popup(url)
      end
    end
  end

  vim.keymap.set("n", "<leader>i", get_node_at_cursor, {})
end

return M
