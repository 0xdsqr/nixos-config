# Neovim Guide For This Setup

This guide is based on your actual config in [modules/eevee/neovim.nix](/Users/dsqr/nixos-config/modules/eevee/neovim.nix).

## First things to know

- Your `leader` key is `Space`.
- Relative line numbers are on, so motions like `5j`, `10k`, `3dd`, `2>>`, `4yy` feel good.
- Search is case-insensitive unless you use capitals.
- Clipboard is wired to the system clipboard.
- Splits open in sane directions: vertical splits to the right, horizontal splits below.
- Which-key is enabled, so pressing `Space` and pausing briefly should show leader shortcuts.

## Must-know custom commands

- `Space pf` find files with Telescope
- `Space pg` live grep across the project
- `Space pb` switch buffers
- `Space pd` search diagnostics
- `Space ps` grep for a typed string
- `Space ss` document symbols
- `Space sS` workspace symbols

- `gd` go to definition
- `gD` go to declaration
- `gr` find references
- `gi` go to implementation
- `gy` go to type definition
- `K` hover docs
- `Space rn` rename symbol
- `Space ca` code action
- `[d` previous diagnostic
- `]d` next diagnostic
- `Space e` show diagnostic under cursor
- `Space q` send diagnostics to location list

- `Space ha` add current file to Harpoon
- `Space hh` open Harpoon menu
- `Space 1` jump to Harpoon file 1
- `Space 2` jump to Harpoon file 2
- `Space 3` jump to Harpoon file 3
- `Space 4` jump to Harpoon file 4

- `Space tt` toggle file tree
- `Space tf` reveal current file in tree

- `Space fm` format current buffer
- `Space nf` run `treefmt` for the whole project
- `Space w` save file

- `Space bn` next buffer
- `Space bp` previous buffer
- `Space bd` close buffer

- `Ctrl-h` move to left split
- `Ctrl-j` move to split below
- `Ctrl-k` move to split above
- `Ctrl-l` move to right split

- In visual mode, `J` moves selected lines down
- In visual mode, `K` moves selected lines up

- `Space y` yank selection to system clipboard
- `Space Y` yank line to system clipboard
- `Space d` delete without overwriting your yank buffer
- In visual mode, `Space p` paste over selection without clobbering the current yank

## Must-know built-in Vim commands

- `h j k l` move left/down/up/right
- `w` next word
- `b` previous word
- `e` end of word
- `0` start of line
- `^` first non-blank on line
- `$` end of line
- `gg` top of file
- `G` bottom of file
- `5j` move down 5 lines
- `10k` move up 10 lines
- `:12` jump to line 12
- `12G` jump to line 12
- `%` jump between matching pairs like `()`, `{}`, `[]`

## Search and jump flow

- `/text` search forward
- `?text` search backward
- `n` next match
- `N` previous match
- `*` search current word forward
- `#` search current word backward
- `Esc` clears current search highlight in your setup
- `Ctrl-d` half-page down and keep cursor centered
- `Ctrl-u` half-page up and keep cursor centered

## Go to definition and come back

- `gd` jumps to definition using Telescope
- `gr` shows references
- `gi` shows implementations
- `gy` shows type definitions
- `Ctrl-o` goes back in the jump list
- `Ctrl-i` goes forward in the jump list
- `''` jumps back to the previous line position

## Selecting, copying, moving, changing

- `v` start character visual mode
- `V` start line visual mode
- `Ctrl-v` start block visual mode
- `y` yank
- `d` delete
- `c` change
- `p` paste after
- `P` paste before
- `u` undo
- `Ctrl-r` redo

- `yy` copy line
- `dd` cut line
- `cc` change line
- `x` delete character
- `r` replace one character
- `.` repeat last change

- `vip` select inside paragraph
- `vi"` select inside quotes
- `vi(` select inside parentheses
- `va(` select around parentheses

## Files, splits, buffers

- `:e path/to/file` open a file
- `:w` save
- `:q` quit window
- `:wq` save and quit
- `:q!` quit without saving
- `:split` horizontal split
- `:vsplit` vertical split
- `:tabnew` open a new tab
- `:Ex` open netrw if you ever want plain built-in file browsing

## File tree workflow

- `Space tt` opens or closes `nvim-tree`
- `Space tf` focuses the current file in the tree
- Your config does not override the tree's default keybindings, so the standard `nvim-tree` keys should still apply
- In the tree, `Enter` opens a file
- In the tree, `q` closes the tree
- In the tree, `a` creates a file or directory
- In the tree, `r` renames
- In the tree, `d` deletes
- In the tree, `R` refreshes
- In the tree, `H` toggles hidden files

That last set is an inference from the fact that your config uses default `nvim-tree` mappings and does not replace them.

## Harpoon workflow that fits this setup

- Mark your main working files with `Space ha`
- Open the list with `Space hh`
- Keep your highest-traffic files in slots `1` to `4`
- Jump with `Space 1`, `Space 2`, `Space 3`, `Space 4`
- This setup saves Harpoon state when toggled and changed, and it tracks marks by git branch

## Telescope workflow that feels good here

- `Space pf` when you know the file exists
- `Space pg` when you know some text exists
- `Space pb` when you already opened the buffer
- `Space pd` when fixing errors
- `Space ss` when exploring symbols in the current file
- `Space sS` when exploring symbols across the project

## Good editing habits for this setup

- Use counts constantly: `5j`, `7k`, `3w`, `4dd`, `>ap`
- Use relative numbers as distance hints, not decoration
- Use `gd` and `Ctrl-o` as your main "inspect and return" loop
- Use `Space pg` for project search instead of trying to navigate manually
- Use Harpoon for 2 to 4 files you bounce between all day
- Use visual `J` and `K` to reorder blocks fast
- Use `Space fm` often and `Space nf` when you want whole-project formatting

## Plugin behavior worth knowing

- `tokyonight-night` theme
- Treesitter highlighting and indenting are enabled
- `blink.cmp` completion is enabled with its default preset
- `Comment.nvim`, `nvim-autopairs`, and `nvim-surround` are enabled with default behavior
- Gitsigns is enabled for hunk navigation and actions
- Last cursor position is restored when reopening files
- Yanked text briefly highlights
- Read-only/help/diagnostic-style windows can be closed with `q`

## Git and shell notes around the editor

These are from your surrounding config, not Neovim itself:

- In Nushell, `vim` aliases to `nvim`
- `lg` aliases to `lazygit`
- Nushell runs in `vi` edit mode
- Your global `EDITOR` and `VISUAL` are still `code --wait`
- Git `core.editor` is also `code --wait`
- Git aliases:
- `git prettylog`
- `git root`
- `git cleanup`
- Tmux prefix is `Space`
- In tmux, `Space -` splits horizontally
- In tmux, `Space \\` splits vertically
- In tmux, `Space h/j/k/l` moves between panes
- In tmux, `Space H/J/K/L` resizes panes
- In tmux, `Space c` opens a new window
- In tmux, `Space x` kills a pane

## No email config found

I did not find a real mail client configuration in this repo. I only found git and Jujutsu identity settings using your email address.

If you want, the next useful step is for me to turn this into an even tighter one-page "daily driver" cheat sheet with only the 20 commands you will actually use every day.
