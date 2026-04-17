{ config, lib, ... }:
let
  inherit (config.dsqr.darwin) exo;
in
lib.mkIf exo.enable { homebrew.casks = [ "ollama" ]; }
