{ nixpkgsPath }: /* lua */ ''
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
      local has_telescope, telescope_builtin = pcall(require, "telescope.builtin")
      local opts = { buffer = ev.buf, noremap = true, silent = true }

      vim.keymap.set("n", "gd", has_telescope and telescope_builtin.lsp_definitions or vim.lsp.buf.definition, vim.tbl_extend("force", opts, { desc = "Go to definition" }))
      vim.keymap.set("n", "gD", vim.lsp.buf.declaration, vim.tbl_extend("force", opts, { desc = "Go to declaration" }))
      vim.keymap.set("n", "gr", has_telescope and telescope_builtin.lsp_references or vim.lsp.buf.references, vim.tbl_extend("force", opts, { desc = "Find references" }))
      vim.keymap.set("n", "gi", has_telescope and telescope_builtin.lsp_implementations or vim.lsp.buf.implementation, vim.tbl_extend("force", opts, { desc = "Go to implementation" }))
      vim.keymap.set("n", "gy", has_telescope and telescope_builtin.lsp_type_definitions or vim.lsp.buf.type_definition, vim.tbl_extend("force", opts, { desc = "Go to type definition" }))

      vim.keymap.set("n", "K", vim.lsp.buf.hover, vim.tbl_extend("force", opts, { desc = "Hover documentation" }))
      vim.keymap.set("i", "<C-k>", vim.lsp.buf.signature_help, vim.tbl_extend("force", opts, { desc = "Signature help" }))

      vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, vim.tbl_extend("force", opts, { desc = "Rename symbol" }))
      vim.keymap.set({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, vim.tbl_extend("force", opts, { desc = "Code action" }))

      vim.keymap.set("n", "[d", function()
        vim.diagnostic.jump({ count = -1, float = true })
      end, vim.tbl_extend("force", opts, { desc = "Previous diagnostic" }))
      vim.keymap.set("n", "]d", function()
        vim.diagnostic.jump({ count = 1, float = true })
      end, vim.tbl_extend("force", opts, { desc = "Next diagnostic" }))
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

  local function package_project_root(markers, dependencies)
    return function(bufnr, on_dir)
      local path = vim.api.nvim_buf_get_name(bufnr)
      local start = path == "" and vim.fn.getcwd() or vim.fs.dirname(path)
      local marker = vim.fs.find(markers, { path = start, upward = true })[1]

      if marker then
        on_dir(vim.fs.dirname(marker))
        return
      end

      local package_json = vim.fs.find("package.json", { path = start, upward = true })[1]
      if not package_json then
        return
      end

      local ok, package = pcall(vim.json.decode, table.concat(vim.fn.readfile(package_json), "\n"))
      if not ok or type(package) ~= "table" then
        return
      end

      for _, section_name in ipairs({ "dependencies", "devDependencies", "peerDependencies" }) do
        local section = package[section_name] or {}
        for _, dependency in ipairs(dependencies) do
          if section[dependency] then
            on_dir(vim.fs.dirname(package_json))
            return
          end
        end
      end
    end
  end

  vim.lsp.config.ts_ls = {
    cmd = { "typescript-language-server", "--stdio" },
    filetypes = { "typescript", "typescriptreact", "javascript", "javascriptreact" },
    root_dir = package_project_root({ "tsconfig.json", "jsconfig.json" }, { "typescript" }),
    workspace_required = true,
  }

  vim.lsp.config.svelte = {
    cmd = { "svelte-language-server", "--stdio" },
    filetypes = { "svelte" },
    root_dir = package_project_root({
      "svelte.config.js",
      "svelte.config.cjs",
      "svelte.config.mjs",
      "svelte.config.ts",
    }, { "svelte", "@sveltejs/kit" }),
    workspace_required = true,
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
    root_dir = package_project_root({
      "tailwind.config.js",
      "tailwind.config.cjs",
      "tailwind.config.mjs",
      "tailwind.config.ts",
    }, { "tailwindcss" }),
    workspace_required = true,
  }

  vim.lsp.config.biome = {
    cmd = { "biome", "lsp-proxy" },
    filetypes = { "typescript", "typescriptreact", "javascript", "javascriptreact", "json", "jsonc" },
    root_dir = package_project_root({ "biome.json", "biome.jsonc" }, { "@biomejs/biome" }),
    workspace_required = true,
  }

  vim.lsp.config.gopls = {
    cmd = { "gopls" },
    filetypes = { "go", "gomod", "gowork", "gotmpl" },
    root_markers = { "go.work", "go.mod" },
    workspace_required = true,
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
    root_markers = { "pyrightconfig.json", "pyproject.toml", "setup.py", "setup.cfg", "requirements.txt", "Pipfile" },
    workspace_required = true,
    settings = {
      python = {
        analysis = {
          autoSearchPaths = true,
          useLibraryCodeForTypes = true,
        },
      },
    },
  }

  vim.lsp.config.nixd = {
    cmd = { "nixd" },
    filetypes = { "nix" },
    root_markers = { "flake.nix", "default.nix", "shell.nix" },
    settings = {
      nixd = {
        nixpkgs = {
          expr = "import ${nixpkgsPath} { }",
        },
        formatting = {
          command = { "nixfmt" },
        },
      },
    },
  }

  vim.lsp.config.lua_ls = {
    cmd = { "lua-language-server" },
    filetypes = { "lua" },
    root_markers = { { ".luarc.json", ".luarc.jsonc" }, ".git" },
    settings = {
      Lua = {
        runtime = { version = "LuaJIT" },
        workspace = { checkThirdParty = false },
        telemetry = { enable = false },
        diagnostics = { globals = { "vim" } },
      },
    },
  }

  vim.lsp.config.jdtls = {
    cmd = { "jdt-language-server" },
    filetypes = { "java" },
    root_markers = { "pom.xml", "build.gradle", "build.gradle.kts" },
    workspace_required = true,
  }

  vim.lsp.config.kotlin_language_server = {
    cmd = { "kotlin-language-server" },
    filetypes = { "kotlin" },
    root_markers = { "settings.gradle", "settings.gradle.kts", "build.gradle", "build.gradle.kts" },
    workspace_required = true,
  }

  vim.lsp.config.bashls = {
    cmd = { "bash-language-server", "start" },
    filetypes = { "sh", "bash" },
    root_markers = { ".git" },
  }

  vim.lsp.config.rust_analyzer = {
    cmd = { "rust-analyzer" },
    filetypes = { "rust" },
    root_markers = { "Cargo.toml", "rust-project.json" },
    workspace_required = true,
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
  vim.lsp.enable("nixd")
  vim.lsp.enable("lua_ls")
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
  local undo_dir = vim.fn.stdpath("state") .. "/undo"
  vim.fn.mkdir(undo_dir, "p")
  vim.opt.undodir = undo_dir
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
    local path = vim.api.nvim_buf_get_name(0)
    if path == "" then
      path = vim.fn.getcwd()
    else
      path = vim.fs.dirname(path)
    end

    local treefmt_config = vim.fs.find({ "treefmt.toml", ".treefmt.toml" }, { path = path, upward = true })[1]
    local flake = vim.fs.find("flake.nix", { path = path, upward = true })[1]
    local command
    local root

    if treefmt_config then
      command = { "treefmt" }
      root = vim.fs.dirname(treefmt_config)
    elseif flake then
      command = { "nix", "fmt" }
      root = vim.fs.dirname(flake)
    else
      vim.notify("No treefmt config or flake.nix found", vim.log.levels.WARN)
      return
    end

    vim.system(command, { cwd = root, text = true }, vim.schedule_wrap(function(result)
      if result.code == 0 then
        vim.notify(table.concat(command, " ") .. ": formatted", vim.log.levels.INFO)
        vim.cmd("checktime")
      else
        local detail = result.stderr ~= "" and result.stderr or "exit code " .. result.code
        vim.notify(table.concat(command, " ") .. ": " .. vim.trim(detail), vim.log.levels.ERROR)
      end
    end))
  end, { desc = "Format project" })

  vim.keymap.set("n", "<Esc>", ":nohlsearch<CR>", { silent = true })

  vim.keymap.set("n", "<leader>bn", ":bnext<CR>", { desc = "Next buffer" })
  vim.keymap.set("n", "<leader>bp", ":bprev<CR>", { desc = "Prev buffer" })
  vim.keymap.set("n", "<leader>bd", ":bdelete<CR>", { desc = "Delete buffer" })
''
