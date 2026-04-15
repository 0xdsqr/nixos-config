{
  config,
  inputs,
  keys,
  lib,
  ...
}:
let
  inherit (lib.filesystem) listFilesRecursive;
  inherit (lib.lists) filter remove;
  inherit (lib.strings) hasSuffix;
  nixFiles = filter (hasSuffix ".nix") (listFilesRecursive ./.);
in
{
  imports = [ inputs.mailserver.nixosModules.default ] ++ remove ./meta.nix (remove ./default.nix nixFiles);

  dsqr.nixos = {
    proxmox.enable = true;

    alloy = {
      enable = true;
      remoteWriteUrl = "http://192.168.50.70:9090/api/v1/write";
    };
  };

  networking.hostName = "blue";
  networking.firewall.allowedTCPPorts = [
    25 # SMTP
    465 # submission SSL
    587 # submission STARTTLS
    993 # IMAPS
  ];

  age.secrets.cloudflareAcmeEnv.file = ./cloudflare-acme.env.age;
  age.secrets.mailMePassword.file = ./me-password.age;

  security.acme = {
    acceptTerms = true;
    defaults.email = "me@dsqr.dev";
    certs."mx.dsqr.dev" = {
      dnsProvider = "cloudflare";
      environmentFile = config.age.secrets.cloudflareAcmeEnv.path;
    };
  };

  mailserver = {
    enable = true;
    stateVersion = 3;
    fqdn = "mx.dsqr.dev";
    sendingFqdn = "mx.dsqr.dev";
    domains = [ "dsqr.dev" ];

    enableImap = true;
    enableSubmission = true;
    x509.useACMEHost = "mx.dsqr.dev";

    accounts."me@dsqr.dev" = {
      passwordFile = config.age.secrets.mailMePassword.path;
      aliases = [
        "m@dsqr.dev"
        "postmaster@dsqr.dev"
        "abuse@dsqr.dev"
      ];
    };
  };

  users.users.dsqr = {
    isNormalUser = true;
    home = "/home/dsqr";
    extraGroups = [
      "wheel"
      "networkmanager"
    ];
    description = "its me dave";
    initialPassword = "changeme";
    openssh.authorizedKeys.keys = keys.admins;
  };

  system.stateVersion = "25.05";
}
