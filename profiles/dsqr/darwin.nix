{ lib, ... }:
let
  inherit (lib.modules) mkDefault;
in
{
  dsqr.darwin = {
    personal.user = {
      enable = mkDefault true;
      name = mkDefault "dsqr";
      home = mkDefault "/Users/dsqr";
    };

    homebrew = {
      enable = mkDefault true;
      user = mkDefault "dsqr";
    };

    grafana = {
      alloy = {
        environment = mkDefault "homelab";
        prometheus.remoteWriteUrl = mkDefault "http://10.10.30.102:9090/api/v1/write";
      };

      loki.writeUrl = mkDefault "http://10.10.30.102:3100/loki/api/v1/push";
    };

    desktop = {
      lapdog.enable = mkDefault true;
      obsidian.enable = mkDefault true;
    };
  };

  home-manager.users.dsqr.dsqr.home.desktop.obsidian = {
    enable = mkDefault true;

    vaults.personal.path = mkDefault "Documents/Obsidian/Personal";
  };
}
