{
  lib,
  pkgs,
  currentSystemUser,
  inputs,
  ...
}:
let
  packages = import ./packages.nix { inherit pkgs; };
in
{
  # Headless-first cluster defaults for macOS nodes.
  services.openssh.enable = true;

  # Standalone cluster baseline (do not depend on dsqr-nix).
  homebrew.enable = true;
  programs.zsh.enable = true;
  environment.shells = with pkgs; [
    bashInteractive
    zsh
  ];

  # Let Determinate Nix manage the nix installation
  nix.enable = false;

  # Determinate Nix installer compatibility (safe if unused).
  ids.gids.nixbld = lib.mkDefault 350;

  # Isolated package set for cluster nodes.
  # Note: Avoid lib.mkForce here as it removes nix-darwin base packages (including darwin-rebuild)
  environment.systemPackages =
    packages.systemPackages
    ++ [ inputs.opencode.packages.${pkgs.stdenv.hostPlatform.system}.default ];
  homebrew.casks = packages.homebrewCasks;
  homebrew.brews = packages.homebrewBrews;

  # Dock customization (Ghostty only, no random Apple apps).
  system.activationScripts.miniClusterDock.text = ''
    if ! /usr/bin/id -u ${currentSystemUser} >/dev/null 2>&1; then
      exit 0
    fi
    DOCKUTIL_BIN="$(/usr/bin/which dockutil 2>/dev/null || true)"
    if [ -z "$DOCKUTIL_BIN" ]; then
      exit 0
    fi
    /usr/bin/su -l ${currentSystemUser} -c "$DOCKUTIL_BIN --no-restart --remove all"
    /usr/bin/su -l ${currentSystemUser} -c "$DOCKUTIL_BIN --no-restart --add /Applications/Ghostty.app"
    /usr/bin/su -l ${currentSystemUser} -c "$DOCKUTIL_BIN --no-restart --add /Applications/Brave\\ Browser.app"
    /usr/bin/killall Dock >/dev/null 2>&1 || true
  '';

  # Power management: keep nodes awake and available.
  system.activationScripts.miniClusterPower.text = ''
    /usr/bin/pmset -a sleep 0 \
      displaysleep 0 \
      disksleep 0 \
      standby 0 \
      autopoweroff 0 \
      womp 1 \
      tcpkeepalive 1 \
      autorestart 1 \
      powernap 1
  '';
}
