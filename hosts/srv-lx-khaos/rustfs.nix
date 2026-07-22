{ inputs, pkgs, ... }:
let
  version = "1.0.0-beta.10";
  package = inputs.rustfs.packages.${pkgs.stdenv.hostPlatform.system}.default.overrideAttrs (_: {
    inherit version;
    src = pkgs.fetchurl {
      url = "https://github.com/rustfs/rustfs/releases/download/${version}/rustfs-linux-x86_64-musl-v${version}.zip";
      hash = "sha256-kAxO9KPjrOJpZDexw7Tiamvak17dy7dy2PkHVicxbVY=";
    };
  });
in
{
  dsqr.nixos.rustfs = {
    enable = true;
    inherit package;
    accessKeyAgeFile = ./rustfs.access-key.age;
    secretKeyAgeFile = ./rustfs.secret-key.age;
  };
}
