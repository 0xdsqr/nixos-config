{ lib, ... }:
let
  inherit (lib) mkEnableOption;
in
{
  options.dsqr.nixos.kubeadm = {
    enable = mkEnableOption "Enable the shared kubeadm baseline";
  };
}
