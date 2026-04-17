{ agenix, pkgs, self, ... }:
let
  agenixPackage = agenix.packages.${pkgs.stdenv.hostPlatform.system}.default;
  moonshotPackage = self.packages.${pkgs.stdenv.hostPlatform.system}.moonshot;
in
{
  environment.systemPackages = with pkgs; [
    agenixPackage
    moonshotPackage
    postgresql
    curl
    fd
    git
    jq
    ripgrep
    wget
  ];
}
