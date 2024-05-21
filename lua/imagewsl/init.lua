local M = {} -- M stands for module, a naming convention

function M.setup()
	print("start")

	local query = vim.treesitter.query.parse("markdown_inline", "(image (link_destination) @url) @image")

	local get_node_at_cursor = function()
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
			end
		end
	end

	vim.keymap.set("n", "<leader>i", get_node_at_cursor, {})

end

return M
