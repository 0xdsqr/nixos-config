{ pkgs, ... }:
{
  # `environment.systemPackages` installs commands into the host system
  # profile so they are available to users on the machine.
  environment.systemPackages = with pkgs; [
    wget
    curl
    vim
    openssl
    git
  ];
}
