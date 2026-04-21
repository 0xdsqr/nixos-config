{ config, lib, ... }:
let
  cfg = config.dsqr.nixos.builder;
in
{
  config = lib.mkIf cfg.enable { nix.settings.trusted-users = lib.mkAfter [ cfg.sshUser ]; };
}
