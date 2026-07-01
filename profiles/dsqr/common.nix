{
  hostMeta ? null,
  hostName ? null,
  lib,
  pkgs,
  self,
  ...
}:
let
  inherit (lib.attrsets) filterAttrs mapAttrs removeAttrs;
  inherit (lib.lists) optional;
  inherit (lib.modules) mkAfter mkDefault;

  keys = import ./keys.nix;

  homeDirectory = if pkgs.stdenv.hostPlatform.isDarwin then "/Users/dsqr" else "/home/dsqr";

  isDarwinHost = hostMeta != null && hostMeta.class == "darwin";
  managesNix = hostMeta != null && hostMeta.class == "nixos";

  hostNameFor = name: host: if host ? sshHost && host.sshHost != null then host.sshHost else name;
  fleetSshHosts = mapAttrs (name: host: { hostName = hostNameFor name host; }) self.hostDefinitions;
  backupSshHosts = mapAttrs (name: host: { hostName = hostNameFor name host; }) (
    filterAttrs (_name: host: host.class == "nixos") self.hostDefinitions
  );

  builderHostName = "srv-lx-khaos";
  builderPublicHostKey = "AAAAC3NzaC1lZDI1NTE5AAAAIO96/hopscQBRbeWkv6CCcCNpe/5lwYt13c3bEWBDkyD";
  builderHost =
    if builtins.hasAttr builderHostName self.hostDefinitions then self.hostDefinitions.${builderHostName} else null;

  rootNixSettings =
    removeAttrs (import (self + /flake.nix)).nixConfig (
      [
        "extra-substituters"
        "extra-trusted-public-keys"
      ]
      ++ optional isDarwinHost "use-cgroups"
    )
    // lib.optionalAttrs isDarwinHost {
      connect-timeout = 30;
      download-attempts = 10;
      http-connections = 4;
      stalled-download-timeout = 900;
    };

  builderMachines = optional (managesNix && builderHost != null && hostName != builderHostName) {
    hostName = if builderHost.sshHost == null then builderHostName else builderHost.sshHost;
    maxJobs = 20;
    publicHostKey = builderPublicHostKey;
    protocol = "ssh-ng";
    sshUser = "build";
    supportedFeatures = [
      "big-parallel"
      "kvm"
    ];
    system = "x86_64-linux";
  };
in
{
  home-manager.sharedModules = mkAfter [ { _module.args = { inherit keys; }; } ];

  home-manager.users.dsqr = {
    home = {
      homeDirectory = mkDefault homeDirectory;
      username = mkDefault "dsqr";
    };

    dsqr.home = {
      nu.agenixIdentityFile = mkDefault ".ssh/dsqr_homelab_ed25519";

      ssh.homelab = {
        enable = mkDefault true;
        user = mkDefault "dsqr";
        identityFile = mkDefault "~/.ssh/dsqr_homelab_ed25519";
        hosts = mkDefault fleetSshHosts;

        backup = {
          enable = mkDefault true;
          user = mkDefault "backup";
          identityFile = mkDefault "~/.ssh/dsqr_homelab_ed25519";
          hosts = mkDefault backupSshHosts;
        };
      };

      versionControl = {
        git = {
          userName = mkDefault "0xdsqr";
          userEmail = mkDefault "me@dsqr.dev";

          github.user = mkDefault "0xdsqr";

          signing = {
            enable = mkDefault true;
            key = mkDefault "6908FE142198DB65";
            ssh.publicKey = mkDefault keys.users.dsqr;
          };
        };

        jj.signing.key = mkDefault keys.users.dsqr;
      };
    };
  };

  dsqr.nix = {
    enable = mkDefault true;
    buildMachines = mkDefault builderMachines;
    distributedBuilds = mkDefault true;
    settings = mapAttrs (_: mkDefault) (rootNixSettings // { builders-use-substitutes = true; });
  };

  dsqr.security.certificates.homeRootCA.enable = mkDefault true;
}
