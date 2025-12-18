# Neovim Getting Started Guide

This guide teaches you everything you need to know about this neovim configuration, assuming you've never used vim/neovim before.

## What is Neovim?

Neovim is a powerful text editor that runs in your terminal. It's modal (different modes for different tasks) and keyboard-driven.

## The Most Important Concept: Modes

Neovim has different **modes** for different tasks:

| Mode | Purpose | How to Enter |
|------|---------|--------------|
| **Normal** | Navigate and manipulate text | `Esc` from any mode |
| **Insert** | Type text (like a normal editor) | `i` from Normal mode |
| **Visual** | Select text | `v` from Normal mode |
| **Command** | Run commands | `:` from Normal mode |

**When you open neovim, you start in Normal mode.**

---

## Opening Neovim

```bash
# Open neovim
nvim

# Open a specific file
nvim myfile.txt

# Open neovim and place cursor at line 42
nvim +42 myfile.txt
```

---

## Exiting Neovim (Very Important!)

People joke about not being able to exit vim. Here's how:

| From Normal Mode | What It Does |
|------------------|--------------|
| `:q` `Enter` | Quit (if no changes) |
| `:q!` `Enter` | Quit without saving (discard changes) |
| `:w` `Enter` | Save (write) |
| `:wq` `Enter` | Save and quit |
| `Space w` | Save (custom keybinding) |
| `ZZ` | Save and quit (fast) |
| `ZQ` | Quit without saving (fast) |

**Note**: Your leader key is `Space`, so `Space w` saves the file.

---

## Part 1: Basic Movement (Normal Mode)

### Character Movement

| Key | Action |
|-----|--------|
| `h` | Move left |
| `j` | Move down |
| `k` | Move up |
| `l` | Move right |

**Or just use arrow keys** (`↑↓←→`) - they work too!

### Word Movement

| Key | Action |
|-----|--------|
| `w` | Next word start |
| `b` | Previous word start |
| `e` | Next word end |

### Line Movement (THE ANSWER TO YOUR QUESTION!)

| Key | Action |
|-----|--------|
| `0` | **Go to START of line** ← This is what you asked for! |
| `^` | Go to first non-whitespace character |
| `$` | Go to END of line |
| `g_` | Go to last non-whitespace character |

**So: `0` = start, `$` = end**

### Screen Movement

| Key | Action |
|-----|--------|
| `gg` | Go to first line of file |
| `G` | Go to last line of file |
| `50G` | Go to line 50 (any number + G) |
| `Ctrl+d` | Half page down (centered) |
| `Ctrl+u` | Half page up (centered) |
| `Ctrl+f` | Full page down |
| `Ctrl+b` | Full page up |
| `H` | Move to top of screen |
| `M` | Move to middle of screen |
| `L` | Move to bottom of screen |

### Jumping Around

| Key | Action |
|-----|--------|
| `%` | Jump to matching bracket/paren |
| `{` | Jump to previous paragraph |
| `}` | Jump to next paragraph |

---

## Part 2: Entering Insert Mode (How to Type!)

From Normal mode, use these to enter Insert mode:

| Key | Action |
|-----|--------|
| `i` | Insert before cursor |
| `a` | Insert after cursor (append) |
| `I` | Insert at start of line |
| `A` | Insert at end of line |
| `o` | **Open new line below** ← How to open next line! |
| `O` | Open new line above |
| `s` | Delete character and insert |
| `S` | Delete line and insert |

**Common workflow**:
1. Navigate in Normal mode
2. Press `i` to insert
3. Type your text
4. Press `Esc` to return to Normal mode

---

## Part 3: Deleting & Changing Text (Normal Mode)

### Basic Deletion

| Key | Action | What Gets Deleted |
|-----|--------|-------------------|
| `x` | Delete character | Under cursor |
| `X` | Delete character | Before cursor |
| `dd` | Delete line | Entire line |
| `D` | Delete to end | From cursor to end of line |
| `dw` | Delete word | From cursor to end of word |
| `db` | Delete word back | From cursor to start of word |
| `d0` | Delete to start | From cursor to start of line |
| `d$` | Delete to end | Same as `D` |

### Changing Text (Delete + Insert Mode)

| Key | Action |
|-----|--------|
| `cc` | Change line (delete line and enter insert) |
| `C` | Change to end of line |
| `cw` | Change word |
| `ciw` | Change inside word (even if cursor in middle) |
| `ci"` | Change inside quotes |
| `ci(` | Change inside parentheses |
| `ci{` | Change inside braces |

---

## Part 4: Copying & Pasting

In vim, copying is called "yanking".

### Copying (Yanking)

| Key | Action |
|-----|--------|
| `yy` | Yank (copy) entire line |
| `Y` | Yank line (same as yy) |
| `yw` | Yank word |
| `y$` | Yank to end of line |
| `yiw` | Yank inside word |

### Custom Clipboard Keybindings

| Key | Action |
|-----|--------|
| `Space y` | Yank to system clipboard (visual mode) |
| `Space Y` | Yank line to system clipboard |

### Pasting

| Key | Action |
|-----|--------|
| `p` | Paste after cursor |
| `P` | Paste before cursor |
| `Space p` | Paste without yanking deleted text |

---

## Part 5: Visual Mode (Selecting Text)

Enter Visual mode to select text:

| Key | Enters Mode |
|-----|-------------|
| `v` | Visual mode (character-wise) |
| `V` | Visual Line mode (line-wise) |
| `Ctrl+v` | Visual Block mode (column selection) |

**Once in Visual mode:**

| Key | Action |
|-----|--------|
| `h/j/k/l` or arrows | Expand selection |
| `y` | Yank (copy) selection |
| `d` | Delete selection |
| `c` | Change selection (delete and insert) |
| `>` | Indent selection right |
| `<` | Indent selection left |
| `Esc` | Exit visual mode |

### Custom Visual Mode Keybindings

| Key | Action |
|-----|--------|
| `J` | Move selected lines down |
| `K` | Move selected lines up |

---

## Part 6: Undo & Redo

| Key | Action |
|-----|--------|
| `u` | Undo |
| `Ctrl+r` | Redo |
| `U` | Undo all changes on line |

---

## Part 7: Search & Replace

### Searching

| Command | Action |
|---------|--------|
| `/searchterm` `Enter` | Search forward |
| `?searchterm` `Enter` | Search backward |
| `n` | Next search result (centered) |
| `N` | Previous search result (centered) |
| `*` | Search for word under cursor (forward) |
| `#` | Search for word under cursor (backward) |
| `Esc` | Clear search highlighting |

### Find & Replace

| Command | Action |
|---------|--------|
| `:s/old/new` | Replace first occurrence on current line |
| `:s/old/new/g` | Replace all occurrences on current line |
| `:%s/old/new/g` | Replace all occurrences in file |
| `:%s/old/new/gc` | Replace all with confirmation |

---

## Part 8: Running External Commands (Without Exiting!)

You can run shell commands from within neovim without exiting.

### Run Command and See Output

| Command | Action |
|---------|--------|
| `:!command` | Run shell command, show output |
| `:!ls` | List files in current directory |
| `:!git status` | Check git status |
| `:!npm test` | Run tests |
| `:!bun run build` | Build your project |

**Example workflow:**
1. Edit `index.ts` in neovim
2. `:!bun run index.ts` - test it
3. See output, press Enter to return
4. Continue editing

### Insert Command Output Into File

| Command | Action |
|---------|--------|
| `:r !command` | Insert command output below cursor |
| `:r !date` | Insert current date/time |
| `:r !ls` | Insert directory listing |
| `:r !curl api.example.com` | Insert API response |

### Run Command on Current File

| Command | Action |
|---------|--------|
| `:!%` | Run current file (if executable) |
| `:!node %` | Run current file with node |
| `:!bun %` | Run current file with bun |
| `:!python3 %` | Run current file with python |

**Note**: `%` represents the current filename.

### Filter Text Through Command

Select text in visual mode, then:

| Command | Action |
|---------|--------|
| `:'<,'>!sort` | Sort selected lines |
| `:'<,'>!uniq` | Remove duplicate lines |
| `:'<,'>!column -t` | Format as table |
| `:'<,'>!jq '.'` | Pretty-print JSON |

### Quick Test Workflow Examples

**TypeScript/JavaScript:**
```
1. Edit file
2. :w                          Save
3. :!bun run %                 Test it
4. See output, press Enter
5. Back to editing
```

**Python:**
```
1. Edit file
2. :w
3. :!python3 %
4. Press Enter
5. Continue
```

**Shell scripts:**
```
1. Edit script.sh
2. :w
3. :!bash %
4. Press Enter
5. Fix bugs, repeat
```

### Run Command in Terminal Split

For persistent output:

```
:terminal
# Opens terminal in split
# Run your commands here
# Ctrl+\ Ctrl+n to exit terminal mode
```

---

## Part 9: Working with Multiple Files

### Buffers

A buffer is a file loaded into memory.

| Custom Keybinding | Action |
|-------------------|--------|
| `Space bn` | Next buffer |
| `Space bp` | Previous buffer |
| `Space bd` | Delete (close) buffer |

### Windows (Split Screens)

| Keybinding | Action |
|------------|--------|
| `:split filename` | Horizontal split |
| `:vsplit filename` | Vertical split |
| `Ctrl+h` | Move to left window |
| `Ctrl+j` | Move to below window |
| `Ctrl+k` | Move to above window |
| `Ctrl+l` | Move to right window |

---

## Part 10: Custom Configuration Features

Your config has a `Space` leader key. Below are all your custom keybindings:

### File Explorer (nvim-tree)

| Keybinding | Action |
|------------|--------|
| `Space tt` | Toggle file tree |
| `Space tf` | Find current file in tree |

**Inside the file tree:**
- `Enter` - Open file
- `o` - Open file/folder
- `a` - Create new file/folder
- `d` - Delete file/folder
- `r` - Rename file/folder
- `x` - Cut file/folder
- `c` - Copy file/folder
- `p` - Paste file/folder
- `q` - Close tree

### Fuzzy Finder (Telescope)

| Keybinding | Action |
|------------|--------|
| `Space pf` | Find files |
| `Space pg` | Live grep (search in files) |
| `Space pb` | Browse buffers |
| `Space ph` | Search help tags |
| `Space ps` | Grep for string |
| `Space pd` | Search diagnostics |

**Inside Telescope:**
- `Ctrl+j` / `↓` - Next result
- `Ctrl+k` / `↑` - Previous result
- `Enter` - Select result
- `Esc` - Close telescope

### Git Integration (Gitsigns)

| Keybinding | Action |
|------------|--------|
| `]c` | Next git hunk (change) |
| `[c` | Previous git hunk |
| `Space hs` | Stage hunk |
| `Space hr` | Reset hunk |
| `Space hp` | Preview hunk |
| `Space hb` | Blame line (show who changed it) |

### LSP (Language Server) Features

**Navigation:**

| Keybinding | Action |
|------------|--------|
| `gd` | Go to definition |
| `gD` | Go to declaration |
| `gr` | Find references |
| `gi` | Go to implementation |
| `gy` | Go to type definition |

**Information:**

| Keybinding | Action |
|------------|--------|
| `K` | Hover documentation (show info about symbol) |
| `Ctrl+k` | Signature help (in insert mode) |

**Actions:**

| Keybinding | Action |
|------------|--------|
| `Space rn` | Rename symbol |
| `Space ca` | Code action (quick fixes) |
| `Space f` | Format file |
| `Space fm` | Format buffer (conform.nvim) |

**Diagnostics (Errors/Warnings):**

| Keybinding | Action |
|------------|--------|
| `[d` | Previous diagnostic |
| `]d` | Next diagnostic |
| `Space e` | Show diagnostic in floating window |
| `Space q` | Send diagnostics to location list |

### Comments

| Keybinding | Action |
|------------|--------|
| `gcc` | Toggle comment on current line (normal mode) |
| `gc` | Toggle comment on selection (visual mode) |

### Autocomplete

Your config uses `blink.cmp` for completion. While typing in Insert mode:

| Key | Action |
|-----|--------|
| `Ctrl+Space` | Trigger completion |
| `Ctrl+n` or `↓` | Next suggestion |
| `Ctrl+p` or `↑` | Previous suggestion |
| `Enter` | Accept suggestion |
| `Esc` | Close completion menu |

---

## Part 11: Essential Workflows

### Workflow 1: Opening and Editing a File

```
1. nvim myfile.js          # Open file
2. i                        # Enter insert mode
3. (type your code)         # Type normally
4. Esc                      # Back to normal mode
5. Space w                  # Save file
6. :q                       # Quit
```

### Workflow 2: Navigate and Edit

```
1. /functionName Enter      # Search for function
2. n n                      # Jump through results
3. ciw                      # Change word under cursor
4. (type new name)          # Type replacement
5. Esc                      # Back to normal mode
6. .                        # Repeat change (magical!)
```

### Workflow 3: Code Navigation with LSP

```
1. Space pf                 # Find file
2. (type filename)          # Search
3. Enter                    # Open file
4. /myFunction Enter        # Find function
5. K                        # Show documentation
6. gd                       # Go to definition
7. Ctrl+o                   # Jump back
```

### Workflow 4: Multi-file Editing

```
1. Space pf                 # Find files
2. (open first file)
3. Space pf                 # Find another file
4. (open second file)
5. Space bn                 # Switch between buffers
6. Space bp                 # Previous buffer
```

### Workflow 5: Git Workflow

```
1. ]c                       # Jump to next change
2. Space hp                 # Preview the change
3. Space hs                 # Stage the change (git add)
4. Space hb                 # See who wrote this line
```

---

## Part 12: Language-Specific Features

Your config has LSP set up for:

### TypeScript/JavaScript
- **LSP**: `ts_ls` (TypeScript language server)
- **Formatter**: `biome` (replaces prettier + eslint)
- **Features**: Autocomplete, go to definition, find references, rename

### Go
- **LSP**: `gopls`
- **Formatters**: `gofumpt`, `goimports`
- **Features**: Full Go support with automatic formatting

### Python
- **LSP**: `pyright`
- **Formatter**: `ruff_format`
- **Features**: Type checking, autocomplete, formatting

### Nix
- **LSP**: `nil`
- **Formatter**: `nixfmt`
- **Features**: Nix language support

**All languages support**: `gd` (definition), `K` (docs), `Space rn` (rename), `Space ca` (code actions)

---

## Part 13: Configuration Files

Your neovim configuration is managed by Nix at:
- `/Users/dsqr/workspace/code/nixos-config/modules/eevee/neovim.nix`

Changes require rebuilding your home-manager configuration.

---

## Quick Reference: Must-Know Keybindings

### Survival Kit (Learn These First)

| Key | Action |
|-----|--------|
| `i` | Enter insert mode |
| `Esc` | Exit to normal mode |
| `:w` Enter | Save |
| `:q` Enter | Quit |
| `h/j/k/l` | Move cursor |
| `0` | **Start of line** |
| `$` | **End of line** |
| `o` | **Open new line below** |
| `O` | Open new line above |
| `dd` | Delete line |
| `yy` | Copy line |
| `p` | Paste |
| `u` | Undo |
| `Ctrl+r` | Redo |
| `/text` Enter | Search |
| `n` | Next search result |

### Custom Keybindings (Your Config)

| Key | Action |
|-----|--------|
| `Space w` | Save file |
| `Space pf` | Find files |
| `Space pg` | Search in files |
| `Space tt` | Toggle file tree |
| `Ctrl+h/j/k/l` | Navigate windows |
| `gd` | Go to definition |
| `K` | Show documentation |
| `Space rn` | Rename symbol |
| `Space fm` | Format code |

---

## Tips for Beginners

1. **Start in Normal mode**: Always press `Esc` when you're not typing. Think of Normal mode as your home base.

2. **Learn by doing**: Open a file and practice. Muscle memory is key.

3. **Use the cheat sheet above**: Keep this guide open while you practice.

4. **Don't memorize everything**: Learn the basics first (insert, navigate, save, quit). Add more as you need them.

5. **The dot command**: In Normal mode, `.` repeats your last change. This is powerful!

6. **Counts work**: `5j` moves down 5 lines. `3dd` deletes 3 lines. `2w` moves 2 words forward.

7. **Operators + Motions**: `d` (delete) + `w` (word) = `dw` (delete word). This pattern is everywhere.

8. **Visual mode when stuck**: If you can't figure out a command, use `v` to select visually, then `d` to delete or `y` to copy.

9. **Use relative line numbers**: Your config has them! Jump to line 7 lines above with `7k`.

10. **Space is your leader**: Most custom commands start with `Space`.

---

## Common Patterns

### The Operator-Motion Pattern

Neovim uses **operator + motion** for many commands:

| Operator | Motion | Result |
|----------|--------|--------|
| `d` (delete) | `w` (word) | Delete word |
| `d` | `$` (end) | Delete to end of line |
| `c` (change) | `iw` (inside word) | Change word |
| `y` (yank) | `y` (line) | Yank line |
| `>` (indent) | `j` (down) | Indent line below |

### Text Objects

Use with operators: `d`, `c`, `y`, etc.

| Text Object | Meaning |
|-------------|---------|
| `iw` | Inside word |
| `aw` | Around word (includes space) |
| `i"` | Inside quotes |
| `a"` | Around quotes (includes quotes) |
| `i(` or `ib` | Inside parentheses |
| `a(` or `ab` | Around parentheses |
| `i{` or `iB` | Inside braces |
| `a{` or `aB` | Around braces |
| `it` | Inside HTML/XML tag |
| `at` | Around tag |

**Examples:**
- `ciw` - Change inside word
- `di"` - Delete inside quotes
- `ya{` - Yank around braces
- `dit` - Delete inside tag

---

## Getting Help

| Command | Action |
|---------|--------|
| `:help keyword` | Search help for keyword |
| `:help i_CTRL-N` | Help for insert mode Ctrl+N |
| `:help :w` | Help for :w command |
| `Space ph` | Search help with telescope |
| `:Tutor` | Built-in interactive tutorial |

---

## Practice Exercises

### Exercise 1: Basic Movement
1. Open any file: `nvim ~/.bashrc`
2. Press `gg` to go to top
3. Press `G` to go to bottom
4. Press `10G` to go to line 10
5. Press `0` then `$` to go to start and end of line
6. Press `:q` to quit

### Exercise 2: Editing
1. Open a new file: `nvim practice.txt`
2. Press `i` and type: "Hello World"
3. Press `Esc`
4. Press `o` and type: "New line"
5. Press `Esc`
6. Press `dd` to delete the line
7. Press `u` to undo
8. Press `:wq` to save and quit

### Exercise 3: Copy and Paste
1. `nvim practice.txt`
2. Press `i` and type a few lines
3. Press `Esc`
4. Press `yy` to copy current line
5. Press `p` to paste below
6. Press `5p` to paste 5 more times
7. Press `:q!` to quit without saving

### Exercise 4: Search and Replace
1. Open a file with repeated words
2. Press `/word` Enter to search
3. Press `n` to jump through matches
4. Press `:%s/word/newword/g` Enter to replace all
5. Press `u` to undo
6. Press `:q` to quit

### Exercise 5: Using Your Config
1. `nvim .`
2. Press `Space tt` to open file tree
3. Navigate with arrows, press Enter to open a file
4. Press `Space pf` to find files
5. Type a filename and press Enter
6. Press `gd` on a function name to go to definition
7. Press `Ctrl+o` to jump back
8. Press `:q` to quit

---

## Next Steps

1. **Complete `:Tutor`**: Run the built-in tutorial (30 minutes)
2. **Practice daily**: Open neovim for all editing tasks
3. **Learn incrementally**: Add 2-3 new keybindings per day
4. **Explore plugins**: Try the telescope and file tree features
5. **Customize**: Once comfortable, tweak `neovim.nix` to your needs

---

## The Vim Philosophy

Vim is designed to keep your hands on the keyboard. The learning curve is steep, but:

- **Week 1**: Frustrating (you'll be slower)
- **Week 2**: Comfortable with basics
- **Week 3**: Faster than before
- **Month 2**: Can't imagine going back

**Stick with it!** The investment pays off tremendously.
