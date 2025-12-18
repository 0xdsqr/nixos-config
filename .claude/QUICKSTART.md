# Quick Start Guide

Essential commands for tmux and Neovim. No fluff.

## Tmux Commands

**Prefix:** `Space` (not `Ctrl+b`)

### Sessions

| Command | Description |
|---------|-------------|
| `tmux` | Start new session |
| `tmux new -s name` | Start named session |
| `tmux ls` | List sessions |
| `tmux attach -t name` | Attach to session |
| `Space d` | Detach from session |
| `Space $` | Rename session |
| `Space s` | List sessions (interactive) |

### Windows

| Command | Description |
|---------|-------------|
| `Space c` | Create window |
| `Space ,` | Rename window |
| `Space n` | Next window |
| `Space p` | Previous window |
| `Space 0-9` | Switch to window number |
| `Space &` | Kill window (confirm) |
| `Space w` | List windows |

### Panes

| Command | Description |
|---------|-------------|
| `Space %` | Split vertical |
| `Space "` | Split horizontal |
| `Space o` | Next pane |
| `Space ;` | Last pane |
| `Space q` | Show pane numbers |
| `Space x` | Kill pane |
| `Space z` | Toggle pane zoom |
| `Space {` | Move pane left |
| `Space }` | Move pane right |
| `Space Space` | Toggle pane layouts |

### Copy Mode

| Command | Description |
|---------|-------------|
| `Space [` | Enter copy mode |
| `Space ]` | Paste buffer |
| `q` | Exit copy mode |
| `Space` (in copy mode) | Start selection |
| `Enter` (in copy mode) | Copy selection |

### Misc

| Command | Description |
|---------|-------------|
| `Space ?` | List keybindings |
| `Space :` | Command prompt |
| `Space t` | Show clock |
| `Mouse` | Enabled (click, drag, scroll) |

---

## Neovim Commands

**Leader:** `Space`

### Must-Know Basics

| Command | Mode | Description |
|---------|------|-------------|
| `i` | Normal | Insert mode (before cursor) |
| `a` | Normal | Insert mode (after cursor) |
| `o` | Normal | New line below |
| `O` | Normal | New line above |
| `Esc` | Any | Back to normal mode |
| `:w` | Normal | Save |
| `:q` | Normal | Quit |
| `:wq` | Normal | Save and quit |
| `:q!` | Normal | Quit without saving |
| `Space w` | Normal | Quick save |

### Navigation

| Command | Mode | Description |
|---------|------|-------------|
| `h j k l` | Normal | Left, down, up, right |
| `w` | Normal | Next word |
| `b` | Normal | Previous word |
| `0` | Normal | Start of line |
| `$` | Normal | End of line |
| `gg` | Normal | Top of file |
| `G` | Normal | Bottom of file |
| `Ctrl+d` | Normal | Half page down (centered) |
| `Ctrl+u` | Normal | Half page up (centered) |
| `{` | Normal | Previous paragraph |
| `}` | Normal | Next paragraph |

### Editing

| Command | Mode | Description |
|---------|------|-------------|
| `x` | Normal | Delete char |
| `dd` | Normal | Delete line |
| `yy` | Normal | Copy line |
| `p` | Normal | Paste after |
| `P` | Normal | Paste before |
| `u` | Normal | Undo |
| `Ctrl+r` | Normal | Redo |
| `.` | Normal | Repeat last action |
| `ciw` | Normal | Change inner word |
| `diw` | Normal | Delete inner word |
| `ci"` | Normal | Change inside quotes |
| `di(` | Normal | Delete inside parens |

### Visual Mode

| Command | Mode | Description |
|---------|------|-------------|
| `v` | Normal | Visual mode (char) |
| `V` | Normal | Visual mode (line) |
| `Ctrl+v` | Normal | Visual block mode |
| `J` | Visual | Move line down |
| `K` | Visual | Move line up |
| `>` | Visual | Indent right |
| `<` | Visual | Indent left |

### Search

| Command | Mode | Description |
|---------|------|-------------|
| `/pattern` | Normal | Search forward |
| `?pattern` | Normal | Search backward |
| `n` | Normal | Next result (centered) |
| `N` | Normal | Previous result (centered) |
| `*` | Normal | Search word under cursor |
| `Esc` | Normal | Clear search highlight |

### Windows

| Command | Mode | Description |
|---------|------|-------------|
| `Ctrl+h` | Normal | Move to left window |
| `Ctrl+j` | Normal | Move to below window |
| `Ctrl+k` | Normal | Move to above window |
| `Ctrl+l` | Normal | Move to right window |
| `:split` | Normal | Horizontal split |
| `:vsplit` | Normal | Vertical split |

### Buffers

| Command | Mode | Description |
|---------|------|-------------|
| `Space bn` | Normal | Next buffer |
| `Space bp` | Normal | Previous buffer |
| `Space bd` | Normal | Delete buffer |
| `Space pb` | Normal | List buffers (Telescope) |

### File Explorer

| Command | Mode | Description |
|---------|------|-------------|
| `Space tt` | Normal | Toggle nvim-tree |
| `Space tf` | Normal | Find current file in tree |
| `Space pv` | Normal | Open netrw |

### Fuzzy Finding (Telescope)

| Command | Mode | Description |
|---------|------|-------------|
| `Space pf` | Normal | Find files |
| `Space pg` | Normal | Live grep (search text) |
| `Space ps` | Normal | Grep with input |
| `Space pb` | Normal | Buffers |
| `Space ph` | Normal | Help tags |
| `Space pd` | Normal | Diagnostics |

### LSP (Language Server)

| Command | Mode | Description |
|---------|------|-------------|
| `gd` | Normal | Go to definition |
| `gD` | Normal | Go to declaration |
| `gr` | Normal | Find references |
| `gi` | Normal | Go to implementation |
| `gy` | Normal | Go to type definition |
| `K` | Normal | Hover documentation |
| `Ctrl+k` | Insert | Signature help |
| `Space rn` | Normal | Rename symbol |
| `Space ca` | Normal/Visual | Code action |
| `[d` | Normal | Previous diagnostic |
| `]d` | Normal | Next diagnostic |
| `Space e` | Normal | Show diagnostic float |
| `Space q` | Normal | Diagnostics to loclist |

### Formatting

| Command | Mode | Description |
|---------|------|-------------|
| `Space fm` | Normal/Visual | Format buffer |
| `Space f` | Normal | LSP format |

### Git (Gitsigns)

| Command | Mode | Description |
|---------|------|-------------|
| `]c` | Normal | Next hunk |
| `[c` | Normal | Previous hunk |
| `Space hs` | Normal | Stage hunk |
| `Space hr` | Normal | Reset hunk |
| `Space hp` | Normal | Preview hunk |
| `Space hb` | Normal | Blame line |

### Clipboard

| Command | Mode | Description |
|---------|------|-------------|
| `Space y` | Normal/Visual | Yank to system clipboard |
| `Space Y` | Normal | Yank line to clipboard |
| `Space p` | Visual | Paste without yanking |
| `Space d` | Normal/Visual | Delete without yanking |

### Comments

| Command | Mode | Description |
|---------|------|-------------|
| `gcc` | Normal | Toggle line comment |
| `gc` | Visual | Toggle comment selection |
| `gbc` | Normal | Toggle block comment |

### Surround

| Command | Mode | Description |
|---------|------|-------------|
| `ys{motion}{char}` | Normal | Add surround |
| `ds{char}` | Normal | Delete surround |
| `cs{old}{new}` | Normal | Change surround |
| `ysiw"` | Normal | Surround word with quotes |
| `ds"` | Normal | Delete surrounding quotes |
| `cs"'` | Normal | Change `"` to `'` |

### Which-key

| Command | Mode | Description |
|---------|------|-------------|
| `Space` (wait) | Normal | Show available keybinds |

---

## Workflow Tips

### Starting a Session

```bash
# Start tmux with named session
tmux new -s dev

# Split into 3 panes
Space %      # Vertical split
Space "      # Horizontal split

# Run different things in each pane
# Pane 1: nvim
# Pane 2: git status && just switch
# Pane 3: journalctl -f
```

### Editing Code

```
1. Space pf          # Find file
2. gd                # Jump to definition
3. K                 # Read docs
4. Space rn          # Rename symbol
5. Space fm          # Format
6. Space w           # Save
```

### Git Workflow

```
1. ]c                # Jump to next change
2. Space hp          # Preview hunk
3. Space hs          # Stage hunk
4. Exit nvim
5. git commit
```

### Searching

```
1. Space pg          # Live grep
2. Type search term
3. Ctrl+n/Ctrl+p     # Navigate results
4. Enter             # Open file
```

---

## Language-Specific

### TypeScript/JavaScript

- LSP: `typescript-language-server` + `biome`
- Format: Biome (on save)
- Lint: Biome (via LSP)

### Go

- LSP: `gopls`
- Format: `gofumpt` + `goimports` (on save)
- `gd` works for stdlib and modules

### Python

- LSP: `pyright`
- Format: `ruff` (on save)
- Type checking: pyright

### Nix

- LSP: `nil`
- Format: `nixfmt` (on save)

---

## Troubleshooting

### LSP Not Working

```vim
:LspInfo              " Check server status
:LspRestart           " Restart servers
:messages             " View error messages
```

### Format Not Working

```vim
:ConformInfo          " Check conform status
:messages             " View errors
```

### Clipboard Issues

```bash
# Ensure clipboard is working
echo "test" | xclip -selection clipboard
xclip -selection clipboard -o
```

### Performance Issues

```vim
:checkhealth          " Run health check
:TSUpdate             " Update treesitter parsers (shouldn't be needed)
```
