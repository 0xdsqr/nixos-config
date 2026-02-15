{ pkgs }:
{
  systemPackages = with pkgs; [
    git
    gh
    tmux
    direnv
    ripgrep
    fd
    jq
    curl
    wget
    python312
  ];

  homebrewCasks = [
    "ghostty"
    "tailscale-app"
    "1password"
    "docker"
    "brave-browser"
  ];

  homebrewBrews = [
    "dockutil"
    "uv"
    "macmon"
    "node"
    "rustup"
    "1password-cli"
  ];
}
