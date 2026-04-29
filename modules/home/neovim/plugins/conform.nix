{ lib, pkgs }:
let
  inherit (lib.lists) singleton;
in
singleton {
  plugin = pkgs.vimPlugins.conform-nvim;
  type = "lua";
  config = /* lua */ ''
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
        typescript = { "treefmt", "biome", stop_after_first = true, lsp_format = "never" },
        typescriptreact = { "treefmt", "biome", stop_after_first = true, lsp_format = "never" },
        javascript = { "treefmt", "biome", stop_after_first = true, lsp_format = "never" },
        javascriptreact = { "treefmt", "biome", stop_after_first = true, lsp_format = "never" },
        svelte = { "treefmt", lsp_format = "never" },
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
