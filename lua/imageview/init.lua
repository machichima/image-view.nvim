local M = {} -- M stands for module, a naming convention

---@type config
M.config = {
	opts = {
		open_type = "explorer",
		-- option:
		-- 1. "explorer": by Windows picture / tmux
		-- 2. "wezterm-tmux"
		-- 3. "kitty-tmux"
		-- 4. "wsl": use `open` command
		-- 5. "feh": use `feh -. filepath` to open the image (only available on linux)
	},
}

local create_popup = function(img_path)
	if M.config.opts.open_type == "explorer" then
		if vim.fn.has("wsl") == 0 then
			error("explorer option is only available on wsl")
		end
		print("use windows explorer")
		vim.cmd("!wsl-open '" .. img_path .. "'")
		print("window explorer opened")
	end

	if M.config.opts.open_type == "wsl" then
		if vim.fn.has("wsl") == 0 then
			error("wsl option is only available on wsl")
		end
		print("use wsl open")
		vim.cmd("!open '" .. img_path .. "'")
		print("wsl opened")
	end

	if M.config.opts.open_type == "wezterm-tmux" then
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

	if M.config.opts.open_type == "kitty-tmux" then
		if vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1 then
			error("kitty does not support windows")
		end

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
		-- vim.cmd('!tmux send-keys -t 1 "kitten icat ' .. img_path .. '" Enter')
		-- !tmux send-keys -t 1 "kitten icat 'img_path'" Enter
		vim.cmd('!tmux send-keys -t 1 "' .. "kitten icat '" .. img_path .. "'" .. '" Enter')
		vim.cmd("!tmux select-pane -l") -- go back to previous pane
	end

	if M.config.opts.open_type == "feh" then
		if vim.fn.has("linux") == 0 then
			error("feh option is only available on linux")
		end
		print("use feh open")
		vim.cmd("!killall feh") -- close all previous feh windows
		vim.cmd("!feh -. '" .. img_path .. "' &") -- show image fit the windows size
		print("feh opened")
	end
end

---@param params config
function M.setup(params)
	-- set up user config
	M.config = vim.tbl_deep_extend("force", {}, M.config, params)

	local client = require("obsidian").get_client()

	local in_obsidian = false -- client.path_is_note(vim.fn.expand("%:p"), client.current_workspace)
	print(client.current_workspace.path)

	M.get_node_at_cursor = function()
		-- the path below is in ~/workData/obsidian/
		-- but the client.current_workspace.path is in /mnt/c/...
		if string.find(vim.fn.resolve(vim.fn.expand("%:p")), tostring(client.current_workspace.path)) then
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

			local start_row, start_col, end_row, end_col = node:range()

			if name == "image" then
				print("element at: ", start_row, start_col, end_row, end_col)
				print("cursor at: ", cursor_row, cursor_col)

				if cursor_row == start_row + 1 and cursor_col >= start_col and cursor_col <= end_col then
					has_img = true
				end
			elseif has_img and name == "url" then
				if cursor_row == start_row + 1 and cursor_col >= start_col and cursor_col <= end_col then
					print(client.current_workspace.path, value)
					if in_obsidian then
						-- For obsidian notes (with incomplete image path)
						local workspace_path = tostring(client.current_workspace.path)
						local attachments_folder = client.opts.attachments.img_folder

						if value:match("^(.-)|") == nil then
							file_name = value
						else
							file_name = value:match("^(.-)|")
						end

						url = workspace_path .. "/" .. attachments_folder .. "/" .. file_name
					else
						-- For other markdown note (with full image path)
						url = value
					end
					print("name: ", name)
					print("value: ", value)
					print("url: ", url)

					if in_obsidian then
					end

					create_popup(url)
				end
			end
		end
	end

	-- vim.keymap.set("n", "<leader>i", M.get_node_at_cursor, {})
end

return M
