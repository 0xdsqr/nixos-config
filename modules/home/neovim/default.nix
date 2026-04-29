{
  flake.homeModules.neovim =
    {
      inputs,
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

      stablePkgs = import inputs.nixpkgs {
        inherit (pkgs.stdenv.hostPlatform) system;
        inherit (pkgs) config;
      };

      pluginSpecs = {
        blinkCmp = {
          file = ./plugins/blink-cmp.nix;
          label = "blink-cmp";
        };
        comment = {
          file = ./plugins/comment.nix;
          label = "comment";
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
        };
        telescopeFzfNative = {
          file = ./plugins/telescope-fzf-native.nix;
          label = "telescope-fzf-native";
        };
        tokyonight = {
          file = ./plugins/tokyonight.nix;
          label = "tokyonight";
        };
        vimSvelte = {
          file = ./plugins/vim-svelte.nix;
          label = "vim-svelte";
        };
        whichKey = {
          file = ./plugins/which-key.nix;
          label = "which-key";
        };
      };

      enabledPluginSpecs = builtins.attrValues (filterAttrs (name: _: cfg.plugins.${name}.enable) pluginSpecs);

      selectedPlugins =
        if cfg.plugins.enable then
          builtins.concatLists (builtins.map (spec: import spec.file { inherit lib pkgs; }) enabledPluginSpecs)
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
          default = stablePkgs.neovim-unwrapped;
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
        programs.neovim.initLua = if cfg.initLua.enable then import ./init-lua.nix else "";
      };
    };
}
