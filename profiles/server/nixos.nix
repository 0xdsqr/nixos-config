{
  networking = {
    dhcpcd.wait = "ipv4";
    nftables.enable = true;
  };

  security.sudo.wheelNeedsPassword = false;

  dsqr.nixos = {
    openssh.enable = true;
    proxmox.enable = true;
    user = {
      enable = true;
      extraGroups = [ "wheel" ];
    };
  };

  home-manager.users.dsqr = {
    programs.pi.enable = false;

    dsqr.home = {
      aws.enable = false;
      bat.enable = false;
      btop.enable = false;
      claudeCode.enable = false;
      codex.enable = false;
      difftastic.enable = false;
      hushlogin.enable = false;
      neovim.enable = false;
      nu.enable = false;
      opencode.enable = false;
      ssh.enable = false;
      starship.enable = false;
      tailscale.enable = false;
      versionControl.enable = false;
      xdg.enable = false;

      packages = {
        containers.enable = false;
        databases.enable = false;
        debugging.enable = false;
        kubernetes.enable = false;
        media.enable = false;
        networkTools.enable = false;
        node.enable = false;
        shellUtils.enable = false;
        signing.enable = false;
      };

      desktop = {
        browsers.helium.enable = false;
        ghostty.enable = false;
      };
    };
  };
}
