{ pkgs, lib, ... }:
let
  inherit (lib.filesystem) listFilesRecursive;
  inherit (lib.lists) filter remove;
  inherit (lib.strings) hasSuffix;
  nixFiles = filter (hasSuffix ".nix") (listFilesRecursive ./.);
in
{
  imports = remove ./meta.nix (remove ./default.nix nixFiles);

  system.stateVersion = 5;
  ids.gids.nixbld = 350;

  # Let Determinate manage the Nix installation on macOS.
  nix.enable = false;

  # The user should already exist, but we need to set this up so Nix knows
  # what our home directory is.
  users.users.dsqr = {
    home = "/Users/dsqr";
    shell = pkgs.zsh;
  };

  system.primaryUser = "dsqr";

  dsqr.darwin.exo.enable = true;
  dsqr.darwin.alloy = {
    enable = true;
    instance = "exo-macmini-01";
    remoteWriteUrl = "http://10.10.30.102:9090/api/v1/write";
    loki.enable = true;
  };
}
