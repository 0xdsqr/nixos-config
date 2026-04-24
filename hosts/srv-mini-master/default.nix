{
  self,
  lib,
  collectHostNix,
  ...
}:
let
  inherit (lib.attrsets) attrValues removeAttrs;
  inherit (lib.lists) singleton;
  modules =
    attrValues self.commonModules
    ++ attrValues (
      removeAttrs self.darwinModules [
        "1password"
        "alloy"
        "browsers"
        "communication"
        "dock"
        "docker-desktop"
        "exo"
        "homebrew"
        "ollama"
        "packages"
        "shells"
        "spotify"
        "tailscale"
        "update"
        "zed"
      ]
    )
    ++ singleton {
      home.extraModules = attrValues (
        removeAttrs self.homeModules [
          "direnv"
          "ghostty"
          "git"
          "neovim"
          "nushell"
          "ssh"
          "starship"
          "tailscale"
          "tmux"
          "zsh"
        ]
      );
    }
    ++ collectHostNix { dir = ./.; };
in
{
  imports = modules;

  system.stateVersion = 5;
  ids.gids.nixbld = 350;

  # Let Determinate manage the Nix installation on macOS.
  nix.enable = false;
  nixpkgs.hostPlatform = lib.mkDefault "aarch64-darwin";

  networking = {
    hostName = "srv-mini-master";
    computerName = "srv-mini-master";
    localHostName = "srv-mini-master";
  };
}
