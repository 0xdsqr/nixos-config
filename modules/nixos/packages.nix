{ agenix, pkgs, ... }:
let
  agenixPackage = agenix.packages.${pkgs.stdenv.hostPlatform.system}.default;
in
{
  environment.systemPackages = with pkgs; [
    agenixPackage
    postgresql
    curl
    fd
    git
    ghostty.terminfo
    jq
    ripgrep
    wget
  ];
}
