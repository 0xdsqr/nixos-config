# Neovim Configuration for Multi-Language Development
# Languages: TypeScript, Go, Python, Nix, Java, Kotlin, Bash, Rust, HTML/CSS, YAML, Markdown, Docker
# Pure Nix approach - no Mason, no runtime downloads
# Uses Neovim 0.11+ native LSP (vim.lsp.config/vim.lsp.enable)
# Updated December 2025
inputs:
{
  config,
  pkgs,
  lib,
  ...
}:
let
  # TreeSitter grammars - installed via Nix, not at runtime
  treesitterWithGrammars = pkgs.vimPlugins.nvim-treesitter.withPlugins (p: [
    p.bash
    p.c
    p.css
    p.dockerfile
    p.go
    p.gomod
    p.gosum
    p.html
    p.java
    p.javascript
    p.json
    p.jsonc
    p.kotlin
    p.lua
    p.markdown
    p.markdown_inline
    p.nix
    p.python
    p.rust
    p.toml
    p.tsx
    p.typescript
    p.vim
    p.vimdoc
    p.yaml
  ]);
in
{
  programs.neovim = {
    enable = true;
    package = inputs.neovim-nightly-overlay.packages.${pkgs.system}.default;
    viAlias = true;
    vimAlias = true;
    vimdiffAlias = true;
    defaultEditor = true;

    # ══════════════════════════════════════════════════════════════════════════
    # LANGUAGE SERVERS & TOOLS
    # These are installed via Nix and available on PATH
    # ══════════════════════════════════════════════════════════════════════════
    extraPackages = with pkgs; [
      # ── Git (REQUIRED for gitsigns, lualine diff, etc.) ──
      git

      # ── TypeScript / JavaScript ──
      typescript
      nodePackages.typescript-language-server
      biome # Replaces prettier + eslint (faster, single tool)

      # ── Go ──
      go
      gopls
      gofumpt
      gotools # includes goimports

      # ── Python ──
      python3
      pyright
      ruff

      # ── Nix ──
      nil # Nix LSP
      nixfmt-rfc-style # Nix formatter

      # ── Java ──
      jdt-language-server
      google-java-format

      # ── Kotlin ──
      kotlin-language-server
      ktlint

      # ── Bash ──
      bash-language-server
      shfmt

      # ── Rust ──
      rust-analyzer
      rustfmt

      # ── Web (HTML/CSS/JSON) ──
      vscode-langservers-extracted

      # ── YAML ──
      yaml-language-server

      # ── Markdown ──
      marksman

      # ── Docker ──
      dockerfile-language-server-nodejs

      # ── General Tools ──
      ripgrep # For telescope live_grep
      fd # For telescope find_files
      treefmt # For conform.nvim formatting via treefmt
    ];

    # ══════════════════════════════════════════════════════════════════════════
    # PLUGINS
    # ══════════════════════════════════════════════════════════════════════════
    plugins = with pkgs.vimPlugins; [
      # ── Theme ──
      {
        plugin = tokyonight-nvim;
        type = "lua";
        config = ''
          vim.cmd.colorscheme("tokyonight-night")
        '';
      }

      # ── Core Dependencies ──
      plenary-nvim

      # ── Fuzzy Finder ──
      {
        plugin = telescope-nvim;
        type = "lua";
        config = ''
          local telescope = require('telescope')
          local builtin = require('telescope.builtin')

          telescope.setup({
            defaults = {
              file_ignore_patterns = { "node_modules", ".git/", "dist/", "build/" },
            },
          })

          vim.keymap.set('n', '<leader>pf', builtin.find_files, { desc = "Find files" })
          vim.keymap.set('n', '<leader>pg', builtin.live_grep, { desc = "Live grep" })
          vim.keymap.set('n', '<leader>pb', builtin.buffers, { desc = "Buffers" })
          vim.keymap.set('n', '<leader>ph', builtin.help_tags, { desc = "Help tags" })
          vim.keymap.set('n', '<leader>ps', function()
            builtin.grep_string({ search = vim.fn.input("Grep > ") })
          end, { desc = "Grep string" })
          vim.keymap.set('n', '<leader>pd', builtin.diagnostics, { desc = "Diagnostics" })
        '';
      }
      telescope-fzf-native-nvim

      # ── TreeSitter ──
      {
        plugin = treesitterWithGrammars;
        type = "lua";
        config = ''
          require('nvim-treesitter.configs').setup({
            auto_install = false,
            highlight = {
              enable = true,
              additional_vim_regex_highlighting = false,
            },
            indent = {
              enable = true,
            },
          })
        '';
      }

      # ── Completion (blink.cmp) ──
      {
        plugin = blink-cmp;
        type = "lua";
        config = ''
          require('blink.cmp').setup({
            keymap = { preset = 'default' },
            appearance = {
              nerd_font_variant = 'mono',
            },
            sources = {
              default = { 'lsp', 'path', 'snippets', 'buffer' },
            },
            signature = {
              enabled = true,
            },
          })
        '';
      }
      friendly-snippets

      # ── Formatting (conform.nvim) ──
      {
        plugin = conform-nvim;
        type = "lua";
        config = ''
          -- Helper: check if this is a treefmt/nix project
          local function has_treefmt(ctx)
            return vim.fs.find(
              { "treefmt.toml", ".treefmt.toml", "flake.nix" },
              { path = ctx.dirname, upward = true }
            )[1] ~= nil
          end

          require('conform').setup({
            formatters = {
              treefmt = {
                command = "treefmt",
                args = { "--stdin", "$FILENAME" },
                stdin = true,
                condition = function(self, ctx)
                  return has_treefmt(ctx)
                end,
              },
            },
            formatters_by_ft = {
              -- treefmt first (skipped if no config), then fallback to biome
              typescript = { "treefmt", "biome", stop_after_first = true, lsp_format = "never" },
              typescriptreact = { "treefmt", "biome", stop_after_first = true, lsp_format = "never" },
              javascript = { "treefmt", "biome", stop_after_first = true, lsp_format = "never" },
              javascriptreact = { "treefmt", "biome", stop_after_first = true, lsp_format = "never" },
              json = { "treefmt", "biome", stop_after_first = true, lsp_format = "never" },
              jsonc = { "treefmt", "biome", stop_after_first = true, lsp_format = "never" },
              nix = { "treefmt", lsp_format = "fallback" },
              go = { "treefmt", "gofumpt", "goimports", stop_after_first = true },
              python = { "treefmt", "ruff_format", stop_after_first = true },
              java = { "treefmt", "google-java-format", stop_after_first = true },
              kotlin = { "treefmt", "ktlint", stop_after_first = true },
              sh = { "treefmt", "shfmt", stop_after_first = true },
              bash = { "treefmt", "shfmt", stop_after_first = true },
              rust = { "treefmt", "rustfmt", stop_after_first = true },
            },
            format_on_save = {
              timeout_ms = 2000,
              lsp_format = "never",
            },
          })

          vim.keymap.set({ "n", "v" }, "<leader>fm", function()
            require("conform").format({ async = true, lsp_format = "fallback" })
          end, { desc = "Format buffer" })
        '';
      }

      # ── Git Integration ──
      {
        plugin = gitsigns-nvim;
        type = "lua";
        config = ''
          require('gitsigns').setup({
            signs = {
              add          = { text = '│' },
              change       = { text = '│' },
              delete       = { text = '_' },
              topdelete    = { text = '‾' },
              changedelete = { text = '~' },
            },
            on_attach = function(bufnr)
              local gs = package.loaded.gitsigns
              local opts = { buffer = bufnr }

              vim.keymap.set('n', ']c', gs.next_hunk, opts)
              vim.keymap.set('n', '[c', gs.prev_hunk, opts)
              vim.keymap.set('n', '<leader>hs', gs.stage_hunk, opts)
              vim.keymap.set('n', '<leader>hr', gs.reset_hunk, opts)
              vim.keymap.set('n', '<leader>hp', gs.preview_hunk, opts)
              vim.keymap.set('n', '<leader>hb', gs.blame_line, opts)
            end,
          })
        '';
      }

      # ── Status Line ──
      {
        plugin = lualine-nvim;
        type = "lua";
        config = ''
          require('lualine').setup({
            options = {
              theme = 'tokyonight',
              component_separators = '|',
              section_separators = "",
            },
            sections = {
              lualine_c = {
                { 'filename', path = 1 }
              },
            },
          })
        '';
      }

      # ── Which-key ──
      {
        plugin = which-key-nvim;
        type = "lua";
        config = ''
          require('which-key').setup({})
        '';
      }

      # ── Comment toggling ──
      {
        plugin = comment-nvim;
        type = "lua";
        config = ''
          require('Comment').setup()
        '';
      }

      # ── Auto pairs ──
      {
        plugin = nvim-autopairs;
        type = "lua";
        config = ''
          require('nvim-autopairs').setup({})
        '';
      }

      # ── Surround text objects ──
      {
        plugin = nvim-surround;
        type = "lua";
        config = ''
          require('nvim-surround').setup({})
        '';
      }

      # ── File explorer ──
      nvim-web-devicons
      {
        plugin = nvim-tree-lua;
        type = "lua";
        config = ''
          require('nvim-tree').setup({
            view = { width = 35 },
            filters = { dotfiles = false },
          })
          vim.keymap.set('n', '<leader>tt', ':NvimTreeToggle<CR>', { desc = "Toggle file tree" })
          vim.keymap.set('n', '<leader>tf', ':NvimTreeFindFile<CR>', { desc = "Find file in tree" })
        '';
      }

      # ── Indent guides ──
      {
        plugin = indent-blankline-nvim;
        type = "lua";
        config = ''
          require('ibl').setup({
            indent = { char = "│" },
            scope = { enabled = true },
          })
        '';
      }
    ];

    # ══════════════════════════════════════════════════════════════════════════
    # BASE CONFIGURATION + LSP (Neovim 0.11+ native)
    # ══════════════════════════════════════════════════════════════════════════
    extraLuaConfig = ''
      -- ════════════════════════════════════════════════════════════════════════
      -- LEADER KEY (must be set before anything else)
      -- ════════════════════════════════════════════════════════════════════════
      vim.g.mapleader = " "
      vim.g.maplocalleader = " "

      -- ════════════════════════════════════════════════════════════════════════
      -- LSP CONFIGURATION (Neovim 0.11+ native - NO lspconfig plugin needed)
      -- ════════════════════════════════════════════════════════════════════════

      -- Global LSP keymaps and settings (applies to ALL language servers)
      vim.api.nvim_create_autocmd('LspAttach', {
        group = vim.api.nvim_create_augroup('UserLspConfig', { clear = true }),
        callback = function(ev)
          local opts = { buffer = ev.buf, noremap = true, silent = true }

          -- ══ GO TO DEFINITION (the main ones you'll use constantly) ══
          vim.keymap.set('n', 'gd', vim.lsp.buf.definition, vim.tbl_extend('force', opts, { desc = "Go to definition" }))
          vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, vim.tbl_extend('force', opts, { desc = "Go to declaration" }))
          vim.keymap.set('n', 'gr', vim.lsp.buf.references, vim.tbl_extend('force', opts, { desc = "Find references" }))
          vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, vim.tbl_extend('force', opts, { desc = "Go to implementation" }))
          vim.keymap.set('n', 'gy', vim.lsp.buf.type_definition, vim.tbl_extend('force', opts, { desc = "Go to type definition" }))

          -- ══ HOVER & SIGNATURE ══
          vim.keymap.set('n', 'K', vim.lsp.buf.hover, vim.tbl_extend('force', opts, { desc = "Hover documentation" }))
          vim.keymap.set('i', '<C-k>', vim.lsp.buf.signature_help, vim.tbl_extend('force', opts, { desc = "Signature help" }))

          -- ══ ACTIONS ══
          vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, vim.tbl_extend('force', opts, { desc = "Rename symbol" }))
          vim.keymap.set({ 'n', 'v' }, '<leader>ca', vim.lsp.buf.code_action, vim.tbl_extend('force', opts, { desc = "Code action" }))
          vim.keymap.set('n', '<leader>f', function() vim.lsp.buf.format({ async = true }) end, vim.tbl_extend('force', opts, { desc = "Format" }))

          -- ══ DIAGNOSTICS ══
          vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, vim.tbl_extend('force', opts, { desc = "Previous diagnostic" }))
          vim.keymap.set('n', ']d', vim.diagnostic.goto_next, vim.tbl_extend('force', opts, { desc = "Next diagnostic" }))
          vim.keymap.set('n', '<leader>e', vim.diagnostic.open_float, vim.tbl_extend('force', opts, { desc = "Show diagnostic" }))
          vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, vim.tbl_extend('force', opts, { desc = "Diagnostics to loclist" }))
        end,
      })

      -- Diagnostic display settings
      vim.diagnostic.config({
        virtual_text = true,
        signs = true,
        underline = true,
        update_in_insert = false,
        severity_sort = true,
        float = {
          border = "rounded",
          source = true,
        },
      })

      -- ══════════════════════════════════════════════════════════════════════
      -- LANGUAGE SERVER DEFINITIONS (Neovim 0.11+ vim.lsp.config)
      -- ══════════════════════════════════════════════════════════════════════

      -- TypeScript/JavaScript (ts_ls)
      vim.lsp.config.ts_ls = {
        cmd = { 'typescript-language-server', '--stdio' },
        filetypes = { 'typescript', 'typescriptreact', 'javascript', 'javascriptreact' },
        root_markers = { 'tsconfig.json', 'jsconfig.json', 'package.json', '.git' },
      }

      -- Biome (linting + formatting for TS/JS/JSON)
      vim.lsp.config.biome = {
        cmd = { 'biome', 'lsp-proxy' },
        filetypes = { 'typescript', 'typescriptreact', 'javascript', 'javascriptreact', 'json', 'jsonc' },
        root_markers = { 'biome.json', 'biome.jsonc', 'package.json', '.git' },
      }

      -- Go (gopls)
      vim.lsp.config.gopls = {
        cmd = { 'gopls' },
        filetypes = { 'go', 'gomod', 'gowork', 'gotmpl' },
        root_markers = { 'go.mod', 'go.work', '.git' },
        settings = {
          gopls = {
            analyses = {
              unusedparams = true,
            },
            staticcheck = true,
            gofumpt = true,
          },
        },
      }

      -- Python (pyright)
      vim.lsp.config.pyright = {
        cmd = { 'pyright-langserver', '--stdio' },
        filetypes = { 'python' },
        root_markers = { 'pyproject.toml', 'setup.py', 'setup.cfg', 'requirements.txt', 'Pipfile', 'pyrightconfig.json', '.git' },
        settings = {
          python = {
            analysis = {
              autoSearchPaths = true,
              useLibraryCodeForTypes = true,
            },
          },
        },
      }

      -- Nix (nil)
      vim.lsp.config.nil_ls = {
        cmd = { 'nil' },
        filetypes = { 'nix' },
        root_markers = { 'flake.nix', 'default.nix', 'shell.nix', '.git' },
        settings = {
          ['nil'] = {
            formatting = {
              command = { 'nix', 'fmt', '--', '-' },
            },
          },
        },
      }

      -- Java (jdtls)
      vim.lsp.config.jdtls = {
        cmd = { 'jdt-language-server' },
        filetypes = { 'java' },
        root_markers = { 'pom.xml', 'build.gradle', 'build.gradle.kts', '.git' },
      }

      -- Kotlin (kotlin_language_server)
      vim.lsp.config.kotlin_language_server = {
        cmd = { 'kotlin-language-server' },
        filetypes = { 'kotlin' },
        root_markers = { 'settings.gradle', 'settings.gradle.kts', 'build.gradle', 'build.gradle.kts', '.git' },
      }

      -- Bash (bashls)
      vim.lsp.config.bashls = {
        cmd = { 'bash-language-server', 'start' },
        filetypes = { 'sh', 'bash' },
        root_markers = { '.git' },
      }

      -- Rust (rust_analyzer)
      vim.lsp.config.rust_analyzer = {
        cmd = { 'rust-analyzer' },
        filetypes = { 'rust' },
        root_markers = { 'Cargo.toml', 'rust-project.json', '.git' },
        settings = {
          ['rust-analyzer'] = {
            cargo = {
              allFeatures = true,
            },
            checkOnSave = {
              command = "clippy",
            },
          },
        },
      }

      -- HTML
      vim.lsp.config.html = {
        cmd = { 'vscode-html-language-server', '--stdio' },
        filetypes = { 'html' },
        root_markers = { 'package.json', '.git' },
      }

      -- CSS
      vim.lsp.config.cssls = {
        cmd = { 'vscode-css-language-server', '--stdio' },
        filetypes = { 'css', 'scss', 'less' },
        root_markers = { 'package.json', '.git' },
      }

      -- YAML
      vim.lsp.config.yamlls = {
        cmd = { 'yaml-language-server', '--stdio' },
        filetypes = { 'yaml', 'yaml.docker-compose' },
        root_markers = { '.git' },
      }

      -- Markdown
      vim.lsp.config.marksman = {
        cmd = { 'marksman', 'server' },
        filetypes = { 'markdown', 'markdown.mdx' },
        root_markers = { '.git', '.marksman.toml' },
      }

      -- Docker
      vim.lsp.config.dockerls = {
        cmd = { 'docker-langserver', '--stdio' },
        filetypes = { 'dockerfile' },
        root_markers = { 'Dockerfile', '.git' },
      }

      -- Enable all configured language servers
      vim.lsp.enable('ts_ls')
      vim.lsp.enable('biome')
      vim.lsp.enable('gopls')
      vim.lsp.enable('pyright')
      vim.lsp.enable('nil_ls')
      vim.lsp.enable('jdtls')
      vim.lsp.enable('kotlin_language_server')
      vim.lsp.enable('bashls')
      vim.lsp.enable('rust_analyzer')
      vim.lsp.enable('html')
      vim.lsp.enable('cssls')
      vim.lsp.enable('yamlls')
      vim.lsp.enable('marksman')
      vim.lsp.enable('dockerls')

      -- ════════════════════════════════════════════════════════════════════════
      -- EDITOR OPTIONS
      -- ════════════════════════════════════════════════════════════════════════

      -- Line Numbers
      vim.opt.nu = true
      vim.opt.relativenumber = true

      -- Indenting
      vim.opt.tabstop = 4
      vim.opt.softtabstop = 4
      vim.opt.shiftwidth = 4
      vim.opt.expandtab = true
      vim.opt.smartindent = true

      -- Line Wraps
      vim.opt.wrap = false

      -- Undo / Swap
      vim.opt.swapfile = false
      vim.opt.backup = false
      vim.opt.undodir = os.getenv("HOME") .. "/.vim/undodir"
      vim.opt.undofile = true

      -- Search
      vim.opt.hlsearch = false
      vim.opt.incsearch = true
      vim.opt.ignorecase = true
      vim.opt.smartcase = true

      -- Scrolling
      vim.opt.scrolloff = 8
      vim.opt.sidescrolloff = 8

      -- UI
      vim.opt.termguicolors = true
      vim.opt.signcolumn = "yes"
      vim.opt.colorcolumn = "80"
      vim.opt.cursorline = true
      vim.opt.showmode = false

      -- Misc
      vim.opt.updatetime = 50
      vim.opt.isfname:append("@-@")
      vim.opt.splitright = true
      vim.opt.splitbelow = true
      vim.opt.clipboard = "unnamedplus"

      -- ════════════════════════════════════════════════════════════════════════
      -- KEYMAPS
      -- ════════════════════════════════════════════════════════════════════════

      -- File explorer
      vim.keymap.set("n", "<leader>pv", vim.cmd.Ex, { desc = "Open netrw" })

      -- Window navigation
      vim.keymap.set("n", "<C-h>", "<C-w>h", { desc = "Move to left window" })
      vim.keymap.set("n", "<C-j>", "<C-w>j", { desc = "Move to below window" })
      vim.keymap.set("n", "<C-k>", "<C-w>k", { desc = "Move to above window" })
      vim.keymap.set("n", "<C-l>", "<C-w>l", { desc = "Move to right window" })

      -- Move lines in visual mode
      vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv", { desc = "Move line down" })
      vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv", { desc = "Move line up" })

      -- Keep cursor centered
      vim.keymap.set("n", "<C-d>", "<C-d>zz", { desc = "Half page down" })
      vim.keymap.set("n", "<C-u>", "<C-u>zz", { desc = "Half page up" })
      vim.keymap.set("n", "n", "nzzzv", { desc = "Next search result" })
      vim.keymap.set("n", "N", "Nzzzv", { desc = "Prev search result" })

      -- Better paste
      vim.keymap.set("x", "<leader>p", '"_dP', { desc = "Paste without yank" })

      -- Clipboard
      vim.keymap.set({ "n", "v" }, "<leader>y", '"+y', { desc = "Yank to clipboard" })
      vim.keymap.set("n", "<leader>Y", '"+Y', { desc = "Yank line to clipboard" })

      -- Delete without yank
      vim.keymap.set({ "n", "v" }, "<leader>d", '"_d', { desc = "Delete without yank" })

      -- Quick save
      vim.keymap.set("n", "<leader>w", ":w<CR>", { desc = "Save file" })

      -- Format entire project with treefmt (silent, async)
      vim.keymap.set("n", "<leader>nf", function()
        vim.fn.jobstart("treefmt", {
          cwd = vim.fn.getcwd(),
          on_exit = function(_, code)
            if code == 0 then
              vim.notify("treefmt: formatted", vim.log.levels.INFO)
              -- Reload any open buffers that changed
              vim.cmd("checktime")
            else
              vim.notify("treefmt: failed", vim.log.levels.ERROR)
            end
          end,
        })
      end, { desc = "Format project with treefmt" })

      -- Clear search
      vim.keymap.set("n", "<Esc>", ":nohlsearch<CR>", { silent = true })

      -- Buffers
      vim.keymap.set("n", "<leader>bn", ":bnext<CR>", { desc = "Next buffer" })
      vim.keymap.set("n", "<leader>bp", ":bprev<CR>", { desc = "Prev buffer" })
      vim.keymap.set("n", "<leader>bd", ":bdelete<CR>", { desc = "Delete buffer" })
    '';
  };
}
