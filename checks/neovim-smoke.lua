local function ensure(condition, message)
  if not condition then
    error("Neovim smoke check: " .. message)
  end
end

ensure(vim.fn.has("nvim-0.12") == 1, "Neovim 0.12 or newer is required")

for _, executable in ipairs({ "fd", "nixd", "nixfmt", "rg", "treefmt" }) do
  ensure(vim.fn.executable(executable) == 1, executable .. " is missing from PATH")
end

for _, module in ipairs({
  "blink.cmp",
  "conform",
  "gitsigns",
  "harpoon",
  "nvim-tree",
  "nvim-treesitter",
  "telescope",
  "which-key",
}) do
  local ok, result = pcall(require, module)
  ensure(ok, string.format("require(%q) failed: %s", module, result))
end

ensure(vim.lsp.config.nixd.cmd[1] == "nixd", "nixd LSP is not configured")
ensure(vim.lsp.config.lua_ls.cmd[1] == "lua-language-server", "Lua LSP is not configured")

local repo = assert(os.getenv("NVIM_SMOKE_REPO"), "NVIM_SMOKE_REPO is unset")
vim.cmd.edit(vim.fs.joinpath(repo, "flake.nix"))

local bufnr = vim.api.nvim_get_current_buf()
ensure(vim.bo[bufnr].filetype == "nix", "flake.nix did not detect the nix filetype")
ensure(vim.treesitter.highlighter.active[bufnr] ~= nil, "Treesitter highlighting is inactive for Nix")
ensure(vim.bo[bufnr].indentexpr:find("nvim%-treesitter") ~= nil, "Treesitter indentation is inactive for Nix")

local conform = require("conform")
local nixfmt = conform.get_formatter_info("nixfmt", bufnr)
local treefmt = conform.get_formatter_info("treefmt", bufnr)
ensure(nixfmt.available, "nixfmt is unavailable to Conform")
ensure(not treefmt.available, "treefmt must require a real treefmt.toml configuration")

ensure(vim.fn.maparg("<leader>nf", "n") ~= "", "project formatting mapping is missing")
ensure(vim.fn.maparg("<leader>ha", "n") ~= "", "Harpoon 2 mapping is missing")

print("Neovim smoke check passed: " .. vim.version().major .. "." .. vim.version().minor .. "." .. vim.version().patch)
