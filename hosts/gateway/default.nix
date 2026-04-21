{ dtil, ... }:
{
  imports = dtil.modules.collectNix {
    dir = ./.;
    ignoredNames = [ "meta.nix" ];
  };

  dsqr.nixos = {
    user = {
      enable = true;
      passwordAgeFile = ./host.password.age;
      serverAdmin.enable = true;
    };

    # this host runs as a proxmox vm; enable the shared guest baseline
    # for grub boot, qemu guest agent, cloud-init disablement, and dhcp defaults.
    proxmox = {
      enable = true;
      hostName = "gateway";
    };

    # this uses our custom module because the tunnel is remotely managed
    # and token-based rather than a local credentials-file setup.
    cloudflared = {
      enable = true;
      tunnelId = "9c851b2c-8644-40a5-8cf4-ae7f63f4a20c";
      tunnelName = "gateway";
      tokenAgeFile = ./cloudflared.token.age;
    };

    alloy = {
      enable = true;
      loki = {
        enable = true;
      };
    };
  };

  system.stateVersion = "25.05";
}
