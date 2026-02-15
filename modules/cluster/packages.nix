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
    uv
    rustup
    nodejs_24
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
    "macmon"
    "1password-cli"
  ];
}
