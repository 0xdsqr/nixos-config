/* lua */ ''
  vim.g.mapleader = " "
  vim.g.maplocalleader = " "

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

  vim.api.nvim_create_autocmd("LspAttach", {
    group = vim.api.nvim_create_augroup("UserLspConfig", { clear = true }),
    callback = function(ev)
      local telescope_builtin = require("telescope.builtin")
      local opts = { buffer = ev.buf, noremap = true, silent = true }

      vim.keymap.set("n", "gd", telescope_builtin.lsp_definitions, vim.tbl_extend("force", opts, { desc = "Go to definition" }))
      vim.keymap.set("n", "gD", vim.lsp.buf.declaration, vim.tbl_extend("force", opts, { desc = "Go to declaration" }))
      vim.keymap.set("n", "gr", telescope_builtin.lsp_references, vim.tbl_extend("force", opts, { desc = "Find references" }))
      vim.keymap.set("n", "gi", telescope_builtin.lsp_implementations, vim.tbl_extend("force", opts, { desc = "Go to implementation" }))
      vim.keymap.set("n", "gy", telescope_builtin.lsp_type_definitions, vim.tbl_extend("force", opts, { desc = "Go to type definition" }))

      vim.keymap.set("n", "K", vim.lsp.buf.hover, vim.tbl_extend("force", opts, { desc = "Hover documentation" }))
      vim.keymap.set("i", "<C-k>", vim.lsp.buf.signature_help, vim.tbl_extend("force", opts, { desc = "Signature help" }))

      vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, vim.tbl_extend("force", opts, { desc = "Rename symbol" }))
      vim.keymap.set({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, vim.tbl_extend("force", opts, { desc = "Code action" }))

      vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, vim.tbl_extend("force", opts, { desc = "Previous diagnostic" }))
      vim.keymap.set("n", "]d", vim.diagnostic.goto_next, vim.tbl_extend("force", opts, { desc = "Next diagnostic" }))
      vim.keymap.set("n", "<leader>e", vim.diagnostic.open_float, vim.tbl_extend("force", opts, { desc = "Show diagnostic" }))
      vim.keymap.set("n", "<leader>q", vim.diagnostic.setloclist, vim.tbl_extend("force", opts, { desc = "Diagnostics to loclist" }))
    end,
  })

  vim.api.nvim_create_autocmd("TextYankPost", {
    group = vim.api.nvim_create_augroup("UserYankHighlight", { clear = true }),
    callback = function()
      vim.highlight.on_yank({ timeout = 200 })
    end,
  })

  vim.api.nvim_create_autocmd("VimResized", {
    group = vim.api.nvim_create_augroup("UserResizeSplits", { clear = true }),
    callback = function()
      vim.cmd("tabdo wincmd =")
    end,
  })

  vim.api.nvim_create_autocmd("BufReadPost", {
    group = vim.api.nvim_create_augroup("UserLastLocation", { clear = true }),
    callback = function(event)
      local exclude = { gitcommit = true }
      local buf = event.buf

      if exclude[vim.bo[buf].filetype] or vim.b[buf].last_location_restored then
        return
      end

      local mark = vim.api.nvim_buf_get_mark(buf, '"')
      local line_count = vim.api.nvim_buf_line_count(buf)

      if mark[1] > 0 and mark[1] <= line_count then
        pcall(vim.api.nvim_win_set_cursor, 0, mark)
        vim.b[buf].last_location_restored = true
      end
    end,
  })

  vim.api.nvim_create_autocmd({ "FocusGained", "TermClose", "TermLeave" }, {
    group = vim.api.nvim_create_augroup("UserCheckTime", { clear = true }),
    callback = function()
      if vim.o.buftype ~= "nofile" then
        vim.cmd("checktime")
      end
    end,
  })

  vim.api.nvim_create_autocmd("FileType", {
    group = vim.api.nvim_create_augroup("UserCloseWithQ", { clear = true }),
    pattern = { "help", "man", "qf", "lspinfo", "checkhealth", "notify" },
    callback = function(event)
      vim.bo[event.buf].buflisted = false
      vim.keymap.set("n", "q", "<cmd>close<CR>", { buffer = event.buf, silent = true, desc = "Close window" })
    end,
  })

  vim.lsp.config.ts_ls = {
    cmd = { "typescript-language-server", "--stdio" },
    filetypes = { "typescript", "typescriptreact", "javascript", "javascriptreact" },
    root_markers = { "tsconfig.json", "jsconfig.json", "package.json", ".git" },
  }

  vim.lsp.config.svelte = {
    cmd = { "svelte-language-server", "--stdio" },
    filetypes = { "svelte" },
    root_markers = {
      "svelte.config.js",
      "svelte.config.cjs",
      "svelte.config.mjs",
      "svelte.config.ts",
      "package.json",
      ".git",
    },
  }

  vim.lsp.config.tailwindcss = {
    cmd = { "tailwindcss-language-server", "--stdio" },
    filetypes = {
      "html",
      "css",
      "scss",
      "less",
      "javascript",
      "javascriptreact",
      "typescript",
      "typescriptreact",
      "svelte",
    },
    root_markers = {
      "tailwind.config.js",
      "tailwind.config.cjs",
      "tailwind.config.mjs",
      "tailwind.config.ts",
      "postcss.config.js",
      "postcss.config.cjs",
      "postcss.config.mjs",
      "postcss.config.ts",
      "package.json",
      ".git",
    },
  }

  vim.lsp.config.biome = {
    cmd = { "biome", "lsp-proxy" },
    filetypes = { "typescript", "typescriptreact", "javascript", "javascriptreact", "json", "jsonc" },
    root_markers = { "biome.json", "biome.jsonc", "package.json", ".git" },
  }

  vim.lsp.config.gopls = {
    cmd = { "gopls" },
    filetypes = { "go", "gomod", "gowork", "gotmpl" },
    root_markers = { "go.mod", "go.work", ".git" },
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

  vim.lsp.config.pyright = {
    cmd = { "pyright-langserver", "--stdio" },
    filetypes = { "python" },
    root_markers = { "pyproject.toml", "setup.py", "setup.cfg", "requirements.txt", "Pipfile", "pyrightconfig.json", ".git" },
    settings = {
      python = {
        analysis = {
          autoSearchPaths = true,
          useLibraryCodeForTypes = true,
        },
      },
    },
  }

  vim.lsp.config.nil_ls = {
    cmd = { "nil" },
    filetypes = { "nix" },
    root_markers = { "flake.nix", "default.nix", "shell.nix", ".git" },
    settings = {
      ["nil"] = {
        formatting = {
          command = { "nix", "fmt", "--", "-" },
        },
      },
    },
  }

  vim.lsp.config.jdtls = {
    cmd = { "jdt-language-server" },
    filetypes = { "java" },
    root_markers = { "pom.xml", "build.gradle", "build.gradle.kts", ".git" },
  }

  vim.lsp.config.kotlin_language_server = {
    cmd = { "kotlin-language-server" },
    filetypes = { "kotlin" },
    root_markers = { "settings.gradle", "settings.gradle.kts", "build.gradle", "build.gradle.kts", ".git" },
  }

  vim.lsp.config.bashls = {
    cmd = { "bash-language-server", "start" },
    filetypes = { "sh", "bash" },
    root_markers = { ".git" },
  }

  vim.lsp.config.rust_analyzer = {
    cmd = { "rust-analyzer" },
    filetypes = { "rust" },
    root_markers = { "Cargo.toml", "rust-project.json", ".git" },
    settings = {
      ["rust-analyzer"] = {
        cargo = {
          allFeatures = true,
        },
        checkOnSave = {
          command = "clippy",
        },
      },
    },
  }

  vim.lsp.config.html = {
    cmd = { "vscode-html-language-server", "--stdio" },
    filetypes = { "html" },
    root_markers = { "package.json", ".git" },
  }

  vim.lsp.config.cssls = {
    cmd = { "vscode-css-language-server", "--stdio" },
    filetypes = { "css", "scss", "less" },
    root_markers = { "package.json", ".git" },
  }

  vim.lsp.config.yamlls = {
    cmd = { "yaml-language-server", "--stdio" },
    filetypes = { "yaml", "yaml.docker-compose" },
    root_markers = { ".git" },
  }

  vim.lsp.config.marksman = {
    cmd = { "marksman", "server" },
    filetypes = { "markdown", "markdown.mdx" },
    root_markers = { ".git", ".marksman.toml" },
  }

  vim.lsp.config.dockerls = {
    cmd = { "docker-langserver", "--stdio" },
    filetypes = { "dockerfile" },
    root_markers = { "Dockerfile", ".git" },
  }

  vim.lsp.enable("ts_ls")
  vim.lsp.enable("svelte")
  vim.lsp.enable("tailwindcss")
  vim.lsp.enable("biome")
  vim.lsp.enable("gopls")
  vim.lsp.enable("pyright")
  vim.lsp.enable("nil_ls")
  vim.lsp.enable("jdtls")
  vim.lsp.enable("kotlin_language_server")
  vim.lsp.enable("bashls")
  vim.lsp.enable("rust_analyzer")
  vim.lsp.enable("html")
  vim.lsp.enable("cssls")
  vim.lsp.enable("yamlls")
  vim.lsp.enable("marksman")
  vim.lsp.enable("dockerls")

  vim.opt.nu = true
  vim.opt.relativenumber = true

  vim.opt.tabstop = 4
  vim.opt.softtabstop = 4
  vim.opt.shiftwidth = 4
  vim.opt.expandtab = true
  vim.opt.smartindent = true

  vim.opt.wrap = false

  vim.opt.swapfile = false
  vim.opt.backup = false
  vim.opt.undodir = os.getenv("HOME") .. "/.vim/undodir"
  vim.opt.undofile = true

  vim.opt.hlsearch = false
  vim.opt.incsearch = true
  vim.opt.ignorecase = true
  vim.opt.smartcase = true

  vim.opt.scrolloff = 8
  vim.opt.sidescrolloff = 8

  vim.opt.termguicolors = true
  vim.opt.signcolumn = "yes"
  vim.opt.colorcolumn = "80"
  vim.opt.cursorline = true
  vim.opt.showmode = false

  vim.opt.autoread = true
  vim.opt.timeoutlen = 300
  vim.opt.updatetime = 50
  vim.opt.isfname:append("@-@")
  vim.opt.splitright = true
  vim.opt.splitbelow = true
  vim.opt.clipboard = "unnamedplus"
  vim.opt.smoothscroll = true

  vim.keymap.set("n", "<C-h>", "<C-w>h", { desc = "Move to left window" })
  vim.keymap.set("n", "<C-j>", "<C-w>j", { desc = "Move to below window" })
  vim.keymap.set("n", "<C-k>", "<C-w>k", { desc = "Move to above window" })
  vim.keymap.set("n", "<C-l>", "<C-w>l", { desc = "Move to right window" })

  vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv", { desc = "Move line down" })
  vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv", { desc = "Move line up" })

  vim.keymap.set("n", "<C-d>", "<C-d>zz", { desc = "Half page down" })
  vim.keymap.set("n", "<C-u>", "<C-u>zz", { desc = "Half page up" })
  vim.keymap.set("n", "n", "nzzzv", { desc = "Next search result" })
  vim.keymap.set("n", "N", "Nzzzv", { desc = "Prev search result" })

  vim.keymap.set("x", "<leader>p", '"_dP', { desc = "Paste without yank" })

  vim.keymap.set({ "n", "v" }, "<leader>y", '"+y', { desc = "Yank to clipboard" })
  vim.keymap.set("n", "<leader>Y", '"+Y', { desc = "Yank line to clipboard" })

  vim.keymap.set({ "n", "v" }, "<leader>d", '"_d', { desc = "Delete without yank" })

  vim.keymap.set("n", "<leader>w", ":w<CR>", { desc = "Save file" })

  vim.keymap.set("n", "<leader>nf", function()
    vim.fn.jobstart("treefmt", {
      cwd = vim.fn.getcwd(),
      on_exit = function(_, code)
        if code == 0 then
          vim.notify("treefmt: formatted", vim.log.levels.INFO)
          vim.cmd("checktime")
        else
          vim.notify("treefmt: failed", vim.log.levels.ERROR)
        end
      end,
    })
  end, { desc = "Format project with treefmt" })

  vim.keymap.set("n", "<Esc>", ":nohlsearch<CR>", { silent = true })

  vim.keymap.set("n", "<leader>bn", ":bnext<CR>", { desc = "Next buffer" })
  vim.keymap.set("n", "<leader>bp", ":bprev<CR>", { desc = "Prev buffer" })
  vim.keymap.set("n", "<leader>bd", ":bdelete<CR>", { desc = "Delete buffer" })
''
