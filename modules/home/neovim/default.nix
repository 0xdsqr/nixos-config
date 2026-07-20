{
  flake.homeModules.neovim =
    {
      lib,
      pkgs,
      config,
      ...
    }:
    let
      inherit (lib.attrsets) filterAttrs mapAttrs;
      inherit (lib.modules) mkIf;
      inherit (lib.options) mkEnableOption mkOption;
      inherit (lib.types) package;

      cfg = config.dsqr.home.neovim;

      pluginSpecs = {
        blinkCmp = {
          file = ./plugins/blink-cmp.nix;
          label = "blink-cmp";
        };
        conform = {
          file = ./plugins/conform.nix;
          label = "conform";
        };
        friendlySnippets = {
          file = ./plugins/friendly-snippets.nix;
          label = "friendly-snippets";
        };
        gitsigns = {
          file = ./plugins/gitsigns.nix;
          label = "gitsigns";
        };
        harpoon = {
          file = ./plugins/harpoon.nix;
          label = "harpoon";
        };
        indentBlankline = {
          file = ./plugins/indent-blankline.nix;
          label = "indent-blankline";
        };
        lualine = {
          file = ./plugins/lualine.nix;
          label = "lualine";
        };
        nvimAutopairs = {
          file = ./plugins/nvim-autopairs.nix;
          label = "nvim-autopairs";
        };
        nvimSurround = {
          file = ./plugins/nvim-surround.nix;
          label = "nvim-surround";
        };
        nvimTree = {
          file = ./plugins/nvim-tree.nix;
          label = "nvim-tree";
        };
        nvimTreesitter = {
          file = ./plugins/nvim-treesitter.nix;
          label = "nvim-treesitter";
        };
        nvimWebDevicons = {
          file = ./plugins/nvim-web-devicons.nix;
          label = "nvim-web-devicons";
        };
        plenary = {
          file = ./plugins/plenary.nix;
          label = "plenary";
        };
        telescope = {
          file = ./plugins/telescope.nix;
          label = "telescope";
          extraArgs.enableFzf = cfg.plugins.telescopeFzfNative.enable;
        };
        telescopeFzfNative = {
          file = ./plugins/telescope-fzf-native.nix;
          label = "telescope-fzf-native";
          condition = cfg.plugins.telescope.enable;
        };
        tokyonight = {
          file = ./plugins/tokyonight.nix;
          label = "tokyonight";
        };
        whichKey = {
          file = ./plugins/which-key.nix;
          label = "which-key";
        };
      };

      enabledPluginSpecs = builtins.attrValues (
        filterAttrs (name: spec: cfg.plugins.${name}.enable && (spec.condition or true)) pluginSpecs
      );

      selectedPlugins =
        if cfg.plugins.enable then
          builtins.concatLists (
            builtins.map (spec: import spec.file ({ inherit lib pkgs; } // (spec.extraArgs or { }))) enabledPluginSpecs
          )
        else
          [ ];
    in
    {
      options.dsqr.home.neovim = {
        enable = mkEnableOption "Neovim editor configuration" // {
          default = true;
        };

        package = mkOption {
          type = package;
          default = pkgs.neovim-unwrapped;
          description = "Neovim package to install and configure.";
        };

        packages.enable = mkEnableOption "extra Neovim tooling packages" // {
          default = true;
        };

        initLua.enable = mkEnableOption "Neovim init.lua configuration" // {
          default = true;
        };

        plugins = {
          enable = mkEnableOption "Neovim plugins" // {
            default = true;
          };
        }
        // mapAttrs (_: spec: {
          enable = mkEnableOption "${spec.label} plugin" // {
            default = true;
          };
        }) pluginSpecs;
      };

      config = mkIf cfg.enable {
        assertions = [
          {
            assertion = !cfg.plugins.enable || !cfg.plugins.telescope.enable || cfg.plugins.plenary.enable;
            message = "dsqr.home.neovim.plugins.telescope requires plenary.";
          }
          {
            assertion = !cfg.plugins.enable || !cfg.plugins.harpoon.enable || cfg.plugins.plenary.enable;
            message = "dsqr.home.neovim.plugins.harpoon requires plenary.";
          }
        ];

        home.sessionVariables.EDITOR = "nvim";
        home.sessionVariables.VISUAL = "nvim";

        programs.neovim.enable = true;
        programs.neovim.package = cfg.package;
        programs.neovim.viAlias = true;
        programs.neovim.vimAlias = true;
        programs.neovim.vimdiffAlias = true;
        programs.neovim.defaultEditor = false;
        programs.neovim.withPython3 = false;
        programs.neovim.withRuby = false;
        programs.neovim.extraPackages = mkIf cfg.packages.enable (import ./packages.nix { inherit pkgs; });
        programs.neovim.plugins = selectedPlugins;
        programs.neovim.initLua = if cfg.initLua.enable then import ./init-lua.nix { nixpkgsPath = pkgs.path; } else "";
      };
    };
}
