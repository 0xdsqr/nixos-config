# Neovim Commands

This is the practical command sheet for this repo's Neovim setup. It covers the core Vim movements plus the custom mappings configured in `init-lua.nix` and `plugins/*.nix`.

## First Principle

Neovim is mode based:

- `Esc`: normal mode, where commands and movement happen.
- `i`: insert mode, where typing edits text.
- `v`: visual mode, select by character.
- `V`: visual line mode, select whole lines.

Your leader key is `Space`. When this guide says `<leader>pf`, press `Space`, then `p`, then `f`.

## Must Know First

If you only memorize one screen, make it this one:

| Key | Action |
| --- | --- |
| `Esc` | Get back to normal mode |
| `i` | Start typing before cursor |
| `a` | Start typing after cursor |
| `:w` or `<leader>w` | Save |
| `:q` | Close current window |
| `u` | Undo |
| `<C-r>` | Redo |
| `gd` | Go to definition |
| `<C-o>` | Go back after jumping |
| `<C-i>` | Go forward again after going back |
| `<leader>pf` | Find files |
| `<leader>pg` | Search text across project |
| `<leader>tt` | Toggle file tree open or closed |
| `<C-h/j/k/l>` | Move between splits/tree/editor |
| `<leader>fm` | Format current buffer |
| `<leader>ca` | Code action |
| `<leader>rn` | Rename symbol |

The shortest answer to "how do I move like VS Code?" is: `<leader>pf` for files, `<leader>pg` for search, `gd` to jump in, `<C-o>` to jump back, `<leader>tt` for the sidebar.

## VS Code Equivalent

The VS Code "Ctrl-click a symbol" habit maps mostly to LSP navigation:

| Key | Action |
| --- | --- |
| `gd` | Go to definition |
| `gD` | Go to declaration |
| `gr` | Find references |
| `gi` | Go to implementation |
| `gy` | Go to type definition |
| `K` | Hover documentation |
| `<C-k>` | Signature help in insert mode |
| `<leader>rn` | Rename symbol |
| `<leader>ca` | Code action |

Start with `gd`, `<C-o>`, `gr`, `K`, `<leader>ca`, and `<leader>rn`. Those are the daily-driver replacements for most VS Code command-palette and click workflows.

## Jump Back And Forward

This is the missing piece after `gd`.

| Key | Action |
| --- | --- |
| `<C-o>` | Jump back to where you came from |
| `<C-i>` | Jump forward again |
| `''` | Jump back to previous line position |
| `` `. `` | Jump to last edit |
| `:jumps` | Show jump history |

Use this flow constantly:

```text
gd       jump to definition
<C-o>    go back
<C-i>    go forward again
```

Marks are manual bookmarks:

| Key | Action |
| --- | --- |
| `ma` | Set mark `a` at cursor |
| `'a` | Jump to line of mark `a` |
| `` `a `` | Jump to exact position of mark `a` |
| `:marks` | Show marks |

Use lowercase marks like `a`, `b`, and `c` inside one file.

## Movement

| Key | Action |
| --- | --- |
| `h` | Left |
| `j` | Down |
| `k` | Up |
| `l` | Right |
| `w` | Next word start |
| `b` | Previous word start |
| `e` | Next word end |
| `0` | Start of line |
| `^` | First nonblank character |
| `$` | End of line |
| `gg` | Top of file |
| `G` | Bottom of file |
| `{` | Previous paragraph/block |
| `}` | Next paragraph/block |
| `%` | Matching bracket, brace, or paren |
| `<C-d>` | Half page down, centered |
| `<C-u>` | Half page up, centered |
| `zz` | Center current line |
| `zt` | Put current line at top |
| `zb` | Put current line at bottom |

Use counts to multiply motions:

| Key | Action |
| --- | --- |
| `5j` | Move down 5 lines |
| `5k` | Move up 5 lines |
| `3w` | Move forward 3 words |
| `10G` | Go to line 10 |
| `10gg` | Go to line 10 |
| `:10` | Go to line 10 |
| `50%` | Go to halfway through the file |

Because relative line numbers are enabled, jumping around with counts is a first-class workflow.

Line-number habit:

```text
7j       move down 7 relative lines
12k      move up 12 relative lines
123G     go to absolute line 123
:123     go to absolute line 123
```

## Editing

| Key | Action |
| --- | --- |
| `i` | Insert before cursor |
| `a` | Insert after cursor |
| `I` | Insert at start of line |
| `A` | Insert at end of line |
| `o` | New line below |
| `O` | New line above |
| `x` | Delete character |
| `dd` | Delete line |
| `D` | Delete from cursor to end of line |
| `cc` | Change whole line |
| `C` | Change from cursor to end of line |
| `yy` | Yank/copy line |
| `p` | Paste after cursor |
| `P` | Paste before cursor |
| `u` | Undo |
| `<C-r>` | Redo |
| `.` | Repeat last edit |
| `J` | Join line below into current line |

Text objects are where Vim gets sharp:

| Key | Action |
| --- | --- |
| `ciw` | Change inner word |
| `diw` | Delete inner word |
| `yiw` | Yank inner word |
| `ci"` | Change inside quotes |
| `di(` | Delete inside parens |
| `ca{` | Change around braces |

Pattern to remember: operator + text object.

- `c` changes.
- `d` deletes.
- `y` yanks.
- `i` means inside.
- `a` means around, including the surrounding delimiter.

## Selection

| Key | Action |
| --- | --- |
| `v` | Visual character selection |
| `V` | Visual line selection |
| `<C-v>` | Visual block selection |
| `J` | Move selected lines down |
| `K` | Move selected lines up |
| `<leader>p` | Paste over selection without replacing your yank |
| `<leader>y` | Yank selection to system clipboard |
| `<leader>d` | Delete selection without yanking |

## Search

| Key | Action |
| --- | --- |
| `/text` | Search forward for `text` |
| `?text` | Search backward for `text` |
| `n` | Next result, centered |
| `N` | Previous result, centered |
| `*` | Search word under cursor |
| `<Esc>` | Clear search highlight |

Search is smart-case: lowercase searches ignore case, mixed-case searches become case-sensitive.

## Files And Project Search

Telescope is the main project navigation UI.

| Key | Action |
| --- | --- |
| `<leader>pf` | Find files |
| `<leader>pg` | Live grep project |
| `<leader>ps` | Prompt for grep search |
| `<leader>pb` | Open buffer picker |
| `<leader>ph` | Search help tags |
| `<leader>pd` | Search diagnostics |
| `<leader>ss` | Document symbols |
| `<leader>sS` | Workspace symbols |

Inside Telescope:

| Key | Action |
| --- | --- |
| `<CR>` | Open selected result |
| `<Esc>` | Close picker |
| `<C-n>` | Next result |
| `<C-p>` | Previous result |
| `<C-j>` | Next result |
| `<C-k>` | Previous result |
| `<C-x>` | Open in horizontal split |
| `<C-v>` | Open in vertical split |
| `<C-t>` | Open in new tab |

File tree:

| Key | Action |
| --- | --- |
| `<leader>tt` | Toggle file tree open or closed |
| `<leader>tf` | Reveal current file in tree |

Inside the file tree:

| Key | Action |
| --- | --- |
| `<CR>` | Open file or directory |
| `o` | Open file or directory |
| `q` | Close tree window |
| `<C-h/j/k/l>` | Move back to editor splits |

Use `<leader>tt` when you just want the sidebar gone. Use `<C-l>` from the tree to get back into the editor.

## Buffers And Windows

Buffers are open files. Windows are splits showing buffers.

| Key | Action |
| --- | --- |
| `<leader>bn` | Next buffer |
| `<leader>bp` | Previous buffer |
| `<leader>bd` | Delete buffer |
| `<C-h>` | Move to left split |
| `<C-j>` | Move to lower split |
| `<C-k>` | Move to upper split |
| `<C-l>` | Move to right split |
| `:split` | Horizontal split |
| `:vsplit` | Vertical split |
| `:q` | Close current window |
| `:only` | Close every other split |
| `<C-w>=` | Equalize split sizes |
| `<C-w>_` | Maximize split height |
| `<C-w>|` | Maximize split width |

Fast split flow:

```text
<leader>tt   open tree
<C-l>        move from tree to editor
:vsplit      open a vertical split
<C-h/l>      move left/right between them
:q           close the split you are in
```

## Diagnostics

Diagnostics are LSP errors, warnings, and hints.

| Key | Action |
| --- | --- |
| `[d` | Previous diagnostic |
| `]d` | Next diagnostic |
| `<leader>e` | Show diagnostic under cursor |
| `<leader>q` | Send diagnostics to location list |
| `<leader>pd` | Telescope diagnostics picker |

## Formatting

Formatting is handled by Conform and project `treefmt`.

| Key | Action |
| --- | --- |
| `<leader>fm` | Format current buffer |
| `<leader>nf` | Run `treefmt` for the whole project |
| `<leader>w` | Save file |
| `:w` | Save file |

Formatting also runs on save. For projects with `treefmt.toml`, `.treefmt.toml`, or `flake.nix`, `treefmt` is preferred.

## Git Hunks

Gitsigns shows changed lines in the sign column and gives hunk commands.

| Key | Action |
| --- | --- |
| `]c` | Next git hunk |
| `[c` | Previous git hunk |
| `<leader>hs` | Stage hunk |
| `<leader>hr` | Reset hunk |
| `<leader>hp` | Preview hunk |
| `<leader>hb` | Blame current line |

## Harpoon

Harpoon is for the handful of files you keep jumping between during a task.

| Key | Action |
| --- | --- |
| `<leader>ha` | Add current file |
| `<leader>hh` | Open Harpoon menu |
| `<leader>1` | Jump to Harpoon file 1 |
| `<leader>2` | Jump to Harpoon file 2 |
| `<leader>3` | Jump to Harpoon file 3 |
| `<leader>4` | Jump to Harpoon file 4 |

Good habit: add your 2-4 active files to Harpoon, then use `<leader>1` through `<leader>4` instead of repeatedly searching.

## Comments, Surrounds, And Completion

These plugins use mostly their default mappings:

| Tool | What to know |
| --- | --- |
| `Comment.nvim` | `gcc` toggles a line comment, `gc` comments a visual selection |
| `nvim-surround` | Add/change/delete surrounding quotes, parens, tags, etc. |
| `blink.cmp` | Completion from LSP, paths, snippets, and buffers |
| `nvim-autopairs` | Auto-closes quotes, parens, brackets, and braces |

Useful surround examples:

| Key | Action |
| --- | --- |
| `ysiw"` | Surround inner word with quotes |
| `ds"` | Delete surrounding quotes |
| `cs"'` | Change surrounding double quotes to single quotes |

Completion basics:

| Key | Action |
| --- | --- |
| `<C-y>` | Accept completion |
| `<C-e>` | Hide completion |
| `<C-n>` | Next completion item |
| `<C-p>` | Previous completion item |

## Built-In Commands Worth Knowing

| Command | Action |
| --- | --- |
| `:w` | Write/save |
| `:q` | Quit current window |
| `:wq` | Save and quit |
| `:q!` | Quit without saving |
| `:e path` | Edit file |
| `:help topic` | Open help |
| `:checkhealth` | Health check |
| `:LspInfo` | LSP client status |
| `:set number!` | Toggle absolute line numbers |
| `:set relativenumber!` | Toggle relative line numbers |
| `:messages` | See recent messages |
| `:map key` | Inspect a mapping |

Useful help targets:

| Command | Action |
| --- | --- |
| `:help jumplist` | Learn `<C-o>` and `<C-i>` |
| `:help motion.txt` | Learn movement |
| `:help text-objects` | Learn `ciw`, `di(`, etc. |
| `:help windows.txt` | Learn splits/windows |
| `:help usr_02.txt` | Neovim/Vim beginner movement |

## What To Practice First

1. Use `Esc`, `i`, `v`, and `V` until modes feel natural.
2. Navigate with `h/j/k/l`, `w/b/e`, `gg/G`, `123G`, and counts like `5j`.
3. Replace click-to-definition with `gd`, then come back with `<C-o>`.
4. Replace project file search with `<leader>pf`.
5. Replace sidebar hunting with `<leader>tt`, `<leader>tf`, and `<C-h/j/k/l>`.
6. Replace project-wide search with `<leader>pg`.
7. Use `<leader>fm` and trust format-on-save.
8. Add active files with `<leader>ha`, then jump with `<leader>1` through `<leader>4`.

If a command starts with `<leader>` and you forget the rest, press `Space` and pause. `which-key` is installed to show available mappings.
