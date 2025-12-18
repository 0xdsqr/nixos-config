# Tmux Getting Started Guide

This guide teaches you everything you need to know about this tmux configuration, from scratch.

## What is Tmux?

Tmux is a terminal multiplexer - it lets you run multiple terminal sessions inside one window. Think of it as tabs and split-screens for your terminal.

## Core Concepts

### Sessions, Windows, and Panes

```
Session (your workspace)
├── Window 1 (like a tab)
│   ├── Pane 1 (split screen)
│   └── Pane 2
└── Window 2
    └── Pane 1
```

- **Session**: Your entire workspace (you can detach and reattach later)
- **Window**: Like a browser tab (numbered 1, 2, 3...)
- **Pane**: Split screen within a window

---

## The Most Important Thing: Prefix Key

**Your prefix key is `Space`** (not the default `Ctrl+B`)

Almost every tmux command starts with: `Space` then another key

Example: To create a new window, you press:
1. `Space` (release it)
2. `c`

We write this as: `Space c`

---

## Essential Commands

### Starting & Managing Sessions

| Command | What It Does |
|---------|-------------|
| `tmux` | Start a new tmux session |
| `tmux new -s myname` | Start a new session named "myname" |
| `tmux ls` | List all sessions |
| `tmux attach -t myname` | Attach to session "myname" |
| `Space d` | Detach from current session (keeps it running) |
| `Space $` | Rename current session |

### Switching Between Sessions

When you have multiple tmux sessions running:

| Command/Keybinding | Action |
|-------------------|--------|
| `tmux ls` | **List all sessions** (from outside tmux) |
| `tmux attach -t myname` | Attach to specific session (from outside tmux) |
| `Space s` | **Interactive session list** (from inside tmux) |
| `Space (` | Switch to previous session |
| `Space )` | Switch to next session |
| `Space L` | Switch to last session (toggle between two) |

**Best workflow for multiple sessions:**

1. Check what sessions exist:
   ```bash
   tmux ls
   # Output:
   # frontend: 3 windows (created Thu Dec 18 12:00:00 2024)
   # backend: 2 windows (created Thu Dec 18 12:05:00 2024)
   # database: 1 windows (attached)
   ```

2. From inside tmux, press `Space s` to see interactive list:
   ```
   (0) + frontend: 3 windows
   (1) + backend: 2 windows
   (2) - database: 1 windows (attached)
   ```
   - Use arrow keys to select
   - Press Enter to switch
   - Press `d` to detach that session
   - Press `x` to kill that session

3. Or quickly toggle between two sessions: `Space L`

**Example multi-session workflow:**
```bash
# Start frontend session
tmux new -s frontend
# (do frontend work)

# Detach
Space d

# Start backend session
tmux new -s backend
# (do backend work)

# Switch back to frontend
Space s  # Interactive menu, select frontend

# Or from terminal
tmux attach -t frontend

# Check all sessions
tmux ls
```

---

## Window Management (Like Browser Tabs)

Your windows are numbered starting at **1** (not 0).

### Window Commands

| Keybinding | Action |
|------------|--------|
| `Space c` | Create new window |
| `Space ,` | Rename current window |
| `Space &` | Kill current window (asks for confirmation) |
| `Space n` | Go to next window |
| `Space p` | Go to previous window |
| `Space 1` | Go to window 1 |
| `Space 2` | Go to window 2 |
| `Space 3` | Go to window 3 |
| ... | (and so on) |
| `Space w` | List all windows (interactive menu) |
| `Space f` | Find window by name |

---

## Pane Management (Split Screens)

### Creating Panes

| Keybinding | Action |
|------------|--------|
| `Space %` | Split pane vertically (side by side) |
| `Space "` | Split pane horizontally (top and bottom) |

### Navigating Between Panes

| Keybinding | Action |
|------------|--------|
| `Space o` | Go to next pane |
| `Space ;` | Go to last active pane |
| `Space q` | Show pane numbers (then type number to jump) |
| `Space {` | Move current pane left |
| `Space }` | Move current pane right |

### Resizing Panes

| Keybinding | Action |
|------------|--------|
| `Space Ctrl+↑` | Resize pane up |
| `Space Ctrl+↓` | Resize pane down |
| `Space Ctrl+←` | Resize pane left |
| `Space Ctrl+→` | Resize pane right |

### Managing Panes

| Keybinding | Action |
|------------|--------|
| `Space x` | Kill current pane (asks for confirmation) |
| `Space z` | Toggle pane zoom (fullscreen/restore) |
| `Space !` | Break pane into its own window |
| `Space Space` | Switch between pane layouts |

---

## Mouse Support

**Your config has mouse support enabled!**

You can:
- Click on panes to switch to them
- Click on window names in the status bar to switch windows
- Drag pane borders to resize them
- Scroll up/down to scroll through terminal history
- Select text with your mouse (use `Space y` plugin features for copying)

---

## Copy Mode (Scrollback)

When you want to scroll through terminal output or copy text:

| Keybinding | Action |
|------------|--------|
| `Space [` | Enter copy mode (now you can scroll) |
| `q` | Exit copy mode |
| `Space PgUp` | Enter copy mode and scroll up one page |

**Inside Copy Mode:**

| Key | Action |
|-----|--------|
| `↑↓←→` | Move cursor |
| `Space` | Start selection |
| `Enter` | Copy selection (with yank plugin, goes to system clipboard) |
| `/` | Search forward |
| `?` | Search backward |
| `n` | Next search result |
| `N` | Previous search result |

---

## Plugins Included

### 1. Sensible
Provides good default settings automatically.

### 2. Yank
**Enhanced clipboard support**

| Keybinding (in copy mode) | Action |
|---------------------------|--------|
| `y` | Copy selection to system clipboard |
| `Y` | Copy current line to system clipboard |

### 3. Better Mouse Mode
Improves mouse scrolling and selection behavior.

### 4. Dracula Theme
Your visual theme (purple/pink color scheme).

---

## Common Workflows

### Workflow 1: Working on Multiple Projects

```bash
# Start named sessions for each project
tmux new -s frontend
# (do frontend work)
Space d  # detach

tmux new -s backend
# (do backend work)
Space d  # detach

# List sessions
tmux ls

# Switch between them
tmux attach -t frontend
tmux attach -t backend
```

### Workflow 2: Split Screen Development

```bash
# Start tmux
tmux

# Split for editor and terminal
Space %     # Split vertically
# Now you have two panes

# In left pane: run neovim
# In right pane: run commands, tests, etc.

# Split right pane again for monitoring
Space "     # Split right pane horizontally
# Now you have editor | terminal
#                      | logs
```

### Workflow 3: Multiple Related Tasks

```bash
# Start tmux
tmux

# Window 1: Editor
Space c     # New window (this is now window 2)
# Window 2: Running server
Space c     # New window (this is now window 3)
# Window 3: Git/commands
Space c     # New window (this is now window 4)
# Window 4: Logs

# Navigate between windows
Space 1  # Jump to editor
Space 2  # Jump to server
# etc.
```

---

## Quick Reference Card

**Session Management:**
- `Space d` - Detach
- `Space $` - Rename session

**Windows (Tabs):**
- `Space c` - New window
- `Space ,` - Rename window
- `Space n/p` - Next/Previous window
- `Space 1-9` - Jump to window number
- `Space &` - Kill window

**Panes (Splits):**
- `Space %` - Split vertically (|)
- `Space "` - Split horizontally (-)
- `Space o` - Next pane
- `Space q` - Show pane numbers
- `Space x` - Kill pane
- `Space z` - Zoom pane (fullscreen toggle)

**Copy Mode:**
- `Space [` - Enter copy mode
- `Space PgUp` - Enter copy mode + page up
- `q` - Exit copy mode
- In copy mode: `Space` to start selection, `Enter` to copy

**Misc:**
- `Space ?` - Show all keybindings
- `Space :` - Enter command mode
- `Space t` - Show time

---

## Configuration Location

Your tmux configuration is managed by Nix at:
- `/Users/dsqr/workspace/code/nixos-config/modules/eevee/tmux.nix`

Changes to this file require rebuilding your home-manager configuration.

---

## Tips for Beginners

1. **Start simple**: Just use windows (tabs) at first. Don't worry about panes until you're comfortable.

2. **Name your windows**: Use `Space ,` to name windows descriptively (e.g., "editor", "server", "tests").

3. **Use the mouse**: Click around! Your config supports mouse, so use it while learning keyboard shortcuts.

4. **Practice the prefix**: `Space` then command. If something doesn't work, you probably forgot the prefix.

5. **Don't panic**: If you get lost, `Space w` shows all windows, `Space q` shows pane numbers.

6. **Zoom is your friend**: `Space z` makes current pane fullscreen. Press again to restore. Great when you need to focus.

7. **Detach freely**: `Space d` to detach. Your session keeps running. Attach later with `tmux attach`.

---

## Next Steps

1. **Practice**: Open tmux and create a few windows. Switch between them.
2. **Try splits**: Create a couple panes, resize them, zoom them.
3. **Work in tmux**: Use it for your actual work. You'll learn by doing.
4. **Explore plugins**: Try the yank plugin's copy features.
5. **Customize**: Once comfortable, you can modify `tmux.nix` to your preferences.

---

## Getting Help

- `Space ?` - Shows all keybindings
- `man tmux` - Full tmux manual
- Official wiki: https://github.com/tmux/tmux/wiki
