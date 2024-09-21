# image-view.nvim

Plugin to display image in the markdown file through:

1. windows explorer
2. image viewer in wsl
3. feh (linux image viewer)
4. tmux vertical split
    - in wezterm or kitty

This can be used in windows wsl and linux system. Option 1, 2, and 3 will open a image viewer window to show the image, while 4 will create the split view in tmux.

It can show the image with markdown link and wiki link: 
- markdown link: open the image with the relative path
- wiki link: Only work with [obsidian.nvim](https://github.com/epwalsh/obsidian.nvim) plugin. Open the image in the folder `attachments.img_folder` set in the `obsidian.nvim` plugin.

> NOTE: currently does not support relative link option in wiki link


## Table of Contents

- [Demo](#demo)
- [Installing](#installing)
- [Lazy](#lazy)
- [Usage](#usage)
- [Configuration](#configuration)


## Demo

> To be added


## Installing

### Lazy

```{json}
{
    'machichima/image-view.nvim',
    event = 'VeryLazy',
    name = "imageview",
    config = function()
        require("imageview").setup({})
    end,
},
```

## Usage

Add keymap to capture and show the image with link under the cursor.

Using Lua:

```{lua}
local imageview = require("imageview")
vim.keymap.set("n", "<leader>i", imageview.get_node_at_cursor, {})
```


## Configuration

Default use the `explorer` option. This can be modified on the setup by:

```{lua}
require("imageview").setup({
    opts = {
        open_type = "explorer",
        -- option:
        -- 1. "explorer": by Windows picture
        -- 2. "wezterm-tmux"
        -- 3. "kitty-tmux"
        -- 4. "wsl": use `open` command
        -- 5. "feh": use `feh -. filepath` to open the image (only available on linux)
    },
})
```
