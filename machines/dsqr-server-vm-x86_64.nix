{
  inputs,
  pkgs,
  ...
}:
{
  imports = [
    ./hardware/vm-x86_64-linux.nix
    (inputs.self.nixosModules.dsqr-proxmox inputs)
  ];

  dsqr.proxmox.networking = {
    hostName = "server";
    firewall.allowedTCPPorts = [
      3000
      3001
      8080
    ];
  };

  services.nginx = {
    enable = true;
    virtualHosts."localhost" = {
      listen = [
        {
          addr = "0.0.0.0";
          port = 8080;
        }
      ];
      locations."/" = {
        proxyPass = "http://localhost:3000/";
        proxyWebsockets = true;
        extraConfig = ''
          proxy_set_header Host $host;
          proxy_set_header X-Real-IP $remote_addr;
          proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
          proxy_set_header X-Forwarded-Proto $scheme;
        '';
      };
    };
  };

  system.stateVersion = "25.05";
}
