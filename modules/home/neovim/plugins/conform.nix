{ lib, pkgs }:
let
  inherit (lib.lists) singleton;
in
singleton {
  plugin = pkgs.vimPlugins.conform-nvim;
  type = "lua";
  config = /* lua */ ''
    require('conform').setup({
      formatters_by_ft = {
        typescript = { "treefmt", "biome", stop_after_first = true },
        typescriptreact = { "treefmt", "biome", stop_after_first = true },
        javascript = { "treefmt", "biome", stop_after_first = true },
        javascriptreact = { "treefmt", "biome", stop_after_first = true },
        svelte = { "treefmt" },
        json = { "treefmt", "biome", stop_after_first = true },
        jsonc = { "treefmt", "biome", stop_after_first = true },
        nix = { "treefmt", "nixfmt", stop_after_first = true },
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
        lsp_format = "fallback",
      },
    })

    vim.keymap.set({ "n", "v" }, "<leader>fm", function()
      require("conform").format({ async = true, lsp_format = "fallback" })
    end, { desc = "Format buffer" })
  '';
}
