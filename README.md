# harpoon-term

Quickly jump to terminals.

*Harpoon Term* is a friendly fork of the `harpoon.term` module from
[harpoon](https://github.com/ThePrimeagent/harpoon).

`harpoon.term` was removed in Harpoon v2 (in the `harpoon2` branch).

This plugin is a minimalist copy of the core features from `harpoon.term`
for use alongside `harpoon2` or standalone.

## Installation

You can install this plugin using your favorite vim package manager, eg.
[vim-plug](https://github.com/junegunn/vim-plug),
[Packer](https://github.com/wbthomason/packer.nvim) or
[lazy](https://github.com/folke/lazy.nvim).

**Packer**:
```lua
use({'davvid/harpoon-term.nvim'})
```

**lazy**:
```lua
{
    'davvid/harpoon-term.nvim'
}
```

**vim-plug**
```VimL
Plug 'davvid/harpoon-term.nvim'
```

## Usage

To bind `goto_terminal(1)` to `<leader><leader>1` and send the current line to terminal 1
using `<leader><leader>c1` use:

```lua
vim.keymap.set({'n', 'v'}, '<leader><leader>1', function()
    require('harpoon_term').goto_terminal(1)
end)

vim.keymap.set('n', '<leader><leader>c1', function()
    local idx = vim.fn.line('.')
    local cmd = vim.api.nvim_buf_get_lines(0, idx - 1, idx, false)[1]
    if cmd == nil then
        return nil
    end
    require('harpoon_term').send_command(1, cmd)
end)
```

## Development

The [Garden file](garden.yaml) can be used to run lint checks using
[Garden](https://gitlab.com/garden-rs/garden).

```sh
# Run lint checks using "luacheck"
garden lint
```

The [github repository](https://github.com/davvid/harpoon-term.nvim)
is a mirror of the main
[repository on gitlab](https://gitlab.com/davvid/harpoon-term.nvim)
where you can file issues and submit merge requests.
