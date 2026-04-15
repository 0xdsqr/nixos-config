{ inputs, ... }:
let
  nixLib = inputs.nixpkgs.lib // inputs.darwin.lib;

  homeModules = {
    direnv = import ./../modules/home/direnv.nix;
    ghostty = import ./../modules/home/ghostty.nix;
    git = import ./../modules/home/git.nix;
    jujutsu = import ./../modules/home/jujutsu.nix;
    neovim = import ./../modules/home/neovim.nix;
    nushell = import ./../modules/home/nushell.nix;
    opencode = import ./../modules/home/opencode.nix;
    sessionVariables = import ./../modules/home/session-variables.nix;
    starship = import ./../modules/home/starship.nix;
    tmux = import ./../modules/home/tmux.nix;
    vscode = import ./../modules/home/vscode.nix;
    zsh = import ./../modules/home/zsh.nix;
  };

  nixosModules = {
    alloy = import ./../modules/nixos/alloy.nix;
    docker = import ./../modules/nixos/docker.nix;
    kubeadm = import ./../modules/nixos/kubeadm/default.nix;
    kubeadmOptions = import ./../modules/nixos/kubeadm/options.nix;
    openssh = import ./../modules/nixos/openssh.nix;
    options = import ./../modules/nixos/options.nix;
    packages = import ./../modules/nixos/packages.nix;
    postgresql = import ./../modules/nixos/postgresql.nix;
    proxmox = import ./../modules/nixos/proxmox.nix;
    restic = import ./../modules/nixos/restic/default.nix;
    shells = import ./../modules/nixos/shells.nix;
    system = import ./../modules/nixos/system.nix;
    tailscale = import ./../modules/nixos/tailscale.nix;
  };

  darwinModules = {
    "1password" = import ./../modules/darwin/1password.nix;
    alloy = import ./../modules/darwin/alloy.nix;
    browsers = import ./../modules/darwin/browsers.nix;
    discord = import ./../modules/darwin/discord.nix;
    dock = import ./../modules/darwin/dock.nix;
    dockerDesktop = import ./../modules/darwin/docker-desktop.nix;
    exo = import ./../modules/darwin/exo.nix;
    ghostty = import ./../modules/darwin/ghostty.nix;
    homebrew = import ./../modules/darwin/homebrew.nix;
    ollama = import ./../modules/darwin/ollama.nix;
    options = import ./../modules/darwin/options.nix;
    packages = import ./../modules/darwin/packages.nix;
    shells = import ./../modules/darwin/shells.nix;
    signalDesktop = import ./../modules/darwin/signal-desktop.nix;
    spotify = import ./../modules/darwin/spotify.nix;
    tailscale = import ./../modules/darwin/tailscale.nix;
    update = import ./../modules/darwin/update.nix;
    zoomDesktop = import ./../modules/darwin/zoom-desktop.nix;
  };
in
{
  flake = {
    lib = nixLib;
    inherit homeModules nixosModules darwinModules;
  };
}
