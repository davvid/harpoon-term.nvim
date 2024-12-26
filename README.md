# harpoon-term

Quickly jump to terminals.

*Harpoon Term* is a standalone version of the `harpoon.term` module from
[Harpoon](https://github.com/ThePrimeagent/harpoon) v1 that has been enhanced
with support for floating windows.

The `harpoon.term` module was removed in Harpoon v2 (Cf. the `harpoon2` branch).

`harpoon-term` provides the functionality from the legacy `harpoon.term` module in a
standalone plugin.



## Installation

You can install this plugin using your favorite vim package manager, eg.
[lazy](https://github.com/folke/lazy.nvim),
[vim-plug](https://github.com/junegunn/vim-plug) or
[Packer](https://github.com/wbthomason/packer.nvim).

**lazy**:
```lua
{
    'davvid/harpoon-term.nvim',
    keys = function()
        local harpoon_term = require('harpoon_term')
        return {
            {
                '<leader>tt',
                function()
                    harpoon_term.toggle_floating_window(nil)
                end,
                desc = 'HarpoonTerm Toggle Floating Window with Current Terminal',
            },
            {
                '<leader>t1',
                function()
                    harpoon_term.toggle_floating_window(1)
                end,
                desc = 'HarpoonTerm Toggle Floating Window with Terminal #1',
            },
            {
                '<leader>t2',
                function()
                    harpoon_term.toggle_floating_window(2)
                end,
                desc = 'HarpoonTerm Toggle Floating Window with Terminal #2',
            },
            {
                '<leader>tc',
                function()
                    local idx = vim.fn.line('.')
                    local cmd = vim.api.nvim_buf_get_lines(0, idx - 1, idx, false)[1]
                    if cmd then
                        harpoon_term.send_command_to_floating_window(nil, cmd)
                    end
                end,
                desc = 'HarpoonTerm Send Line to Current Terminal in a Floating Window',
            },
            {
                '<leader><leader>c1',
                function()
                    local idx = vim.fn.line('.')
                    local cmd = vim.api.nvim_buf_get_lines(0, idx - 1, idx, false)[1]
                    if cmd then
                        harpoon_term.send_command_to_floating_window(1, cmd)
                    end
                end,
                desc = 'HarpoonTerm Send Line to Terminal #1 in a Floating Window',
            },
            {
                '<leader><leader>1',
                function()
                    harpoon_term.goto_terminal(1)
                end,
                desc = 'HarpoonTerm Switch to Terminal #1',
            },
            {
                '<leader><leader>2',
                function()
                    harpoon_term.goto_terminal(2)
                end,
                desc = 'HarpoonTerm Switch to Terminal #2',
            },
        }
    end,
}
```

**vim-plug**
```VimL
Plug 'davvid/harpoon-term.nvim'
```

**Packer**:
```lua
use({'davvid/harpoon-term.nvim'})
```


## Usage

Terminals are identified by "Termainl IDs" which are integers starting at `1`.
Specify `nil` as the Terminal ID to automatically use the most recently used terminal.

The following example keybindings demonstrate how to use this plugin.

To bind `<leader><leader>1` so that it opens Terminal #1 use the following snippet in
your `init.lua`:

```lua
-- Switch to Terminal #1.
vim.keymap.set({'n', 'v'}, '<leader><leader>1', function()
    require('harpoon_term').goto_terminal(1)
end)
```

The `goto_terminal(idx)` function switches the current buffer to the specified terminal ID.

To bind `<leader><leader>c1` so that it sends the current line to Terminal #1 use the
following snippet in your `init.lua`:

```lua
-- Send the current line to Terminal #1.
vim.keymap.set('n', '<leader><leader>c1', function()
    local idx = vim.fn.line('.')
    local cmd = vim.api.nvim_buf_get_lines(0, idx - 1, idx, false)[1]
    if cmd then
        require('harpoon_term').send_command(1, cmd)
    end
end)
```

As mentioned above, replace the the number `1` with `nil` in the `goto_terminal(...)`
and `send_command(...)` calls to automatically use the most recently used terminal.

Floating windows can be used to open terminal instead of using the current buffer.

```lua
-- Toggle a Floating Window with the Current Terminal.
vim.keymap.set({'n', 'v'}, '<leader>tt', function()
    require('harpoon_term').toggle_floating_window(nil)
end)

-- Toggle a Floating Window with Terminal #1.
vim.keymap.set({'n', 'v'}, '<leader>t1', function()
    require('harpoon_term').toggle_floating_window(1)
end)

-- Send the current line to the most recently used Terminal in a floating window.
vim.keymap.set('n', '<leader>tc', function()
    local idx = vim.fn.line('.')
    local cmd = vim.api.nvim_buf_get_lines(0, idx - 1, idx, false)[1]
    if cmd then
        require('harpoon_term').send_command_to_floating_window(nil, cmd)
    end
end)
```

Press `<ESC>` or `<Ctrl-c>` in Normal Mode when the floating window is open to close the
window.


## Development

The [Garden file](garden.yaml) can be used to run lint checks using
[Garden](https://gitlab.com/garden-rs/garden).

```sh
# Run lint checks using "luacheck"
garden check
```

The documentation is generated using [panvimdoc](https://github.com/kdheepak/panvimdoc.git).

```bash
garden setup  # one-time setup
garden doc
```

Use `garden fmt` to apply code formatting using [stylua](https://github.com/JohnnyMorganz/StyLua).

The [github repository](https://github.com/davvid/harpoon-term.nvim)
is a mirror of the main
[repository on gitlab](https://gitlab.com/davvid/harpoon-term.nvim)
where you can file issues and submit merge requests.
