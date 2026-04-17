{ config, lib, ... }:
let
  inherit (config.dsqr.darwin) devbox;
in
lib.mkIf devbox.enable { homebrew.casks = [ "discord" ]; }
