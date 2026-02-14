{
  lib,
  pkgs,
  currentSystemUser,
  ...
}:
{
  # Headless-first cluster defaults for macOS nodes.
  services.openssh.enable = true;

  # Keep GUI casks minimal; leave tailscale-app enabled.
  eevee.darwin.exclude_casks = [
    "spotify"
    "1password"
    "cleanshot"
    "discord"
    "raycast"
    "obsidian"
    "vlc"
    "signal"
    "typora"
    "dropbox"
    "chromium"
    "tigervnc-viewer"
    "microsoft-remote-desktop"
    "remoteviewer"
  ];

  # Ensure flake support is on across nodes.
  nix.settings.experimental-features = "nix-command flakes";

  # Determinate Nix installer compatibility (safe if unused).
  ids.gids.nixbld = lib.mkDefault 350;

  # Dock customization (Ghostty only, no random Apple apps).
  homebrew.brews = [ "dockutil" ];

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
    /usr/bin/killall Dock >/dev/null 2>&1 || true
  '';

  # Basic CLI tooling for cluster nodes.
  environment.systemPackages = with pkgs; [
    git
    tmux
    direnv
    ripgrep
    fd
    jq
    curl
    wget
    python312
  ];

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
