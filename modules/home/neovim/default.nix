{
  flake.homeModules.neovim =
    { inputs, pkgs, ... }:
    let
      inherit (pkgs.lib.lists) filter;
      inherit (pkgs.lib.strings) hasSuffix;

      stablePkgs = import inputs.nixpkgs {
        inherit (pkgs.stdenv.hostPlatform) system;
        inherit (pkgs) config;
      };

      collectNix =
        dir: builtins.sort builtins.lessThan (filter (name: hasSuffix ".nix" name) (builtins.attrNames (builtins.readDir dir)));
    in
    {
      home.sessionVariables.EDITOR = "nvim";
      home.sessionVariables.VISUAL = "nvim";

      programs.neovim = {
        enable = true;
        package = stablePkgs.neovim-unwrapped;
        viAlias = true;
        vimAlias = true;
        vimdiffAlias = true;
        defaultEditor = false;
        withPython3 = false;
        withRuby = false;

        extraPackages = import ./packages.nix { inherit pkgs; };
        plugins = builtins.concatLists (map (name: import (./plugins + "/${name}") { inherit pkgs; }) (collectNix ./plugins));
        initLua = import ./init-lua.nix;
      };
    };
}
