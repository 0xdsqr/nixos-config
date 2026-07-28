{ inputs, pkgs, ... }:
let
  version = "1.0.0-beta.11";
  package = inputs.rustfs.packages.${pkgs.stdenv.hostPlatform.system}.default.overrideAttrs (_: {
    inherit version;
    src = pkgs.fetchurl {
      url = "https://github.com/rustfs/rustfs/releases/download/${version}/rustfs-linux-x86_64-musl-v${version}.zip";
      hash = "sha256-E3vLSdlLGdB5aISVnjuITkxbcBxEGsClXsrc0ywNIyA=";
    };
  });
  certificate = {
    directory = "/var/lib/rustfs/tls";
    certificateFile = "/var/lib/rustfs/tls/rustfs_cert.pem";
    privateKeyFile = "/var/lib/rustfs/tls/rustfs_key.pem";
  };
in
{
  dsqr.nixos.rustfs = {
    enable = true;
    inherit package;
    address = "10.10.30.107:9000";
    accessKeyAgeFile = ./rustfs.access-key.age;
    consoleAddress = "10.10.30.107:9001";
    secretKeyAgeFile = ./rustfs.secret-key.age;
    tlsDirectory = certificate.directory;
  };

  dsqr.nixos.vaultCertificates.rustfs = {
    roleId = "e8b1c7b0-da79-456a-b59b-60c9c849386b";
    secretIdAgeFile = ./rustfs-listener-pki.secret-id.age;
    issuePath = "pki_int/issue/rustfs-khaos-listener";
    commonName = "rustfs.service.home.arpa";
    inherit (certificate) directory certificateFile privateKeyFile;
    owner = "rustfs";
    group = "rustfs";
    reloadUnit = "rustfs.service";
  };

  networking.firewall.extraInputRules = ''
    ip saddr 10.10.60.100/32 tcp dport { 9000, 9001 } accept
  '';
}
