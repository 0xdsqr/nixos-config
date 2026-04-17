{ pkgs, ... }:
{
  services.vault = {
    enable = true;
    package = pkgs.vault-bin;
    address = "0.0.0.0:8200";
    storageBackend = "raft";
    extraConfig = ''
      ui = true
      api_addr = "http://192.168.50.71:8200"
      cluster_addr = "http://192.168.50.71:8201"
      disable_mlock = true
    '';
  };

  networking.firewall.allowedTCPPorts = [ 8200 ];
}
