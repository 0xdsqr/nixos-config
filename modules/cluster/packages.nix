{ pkgs }:
{
  systemPackages = with pkgs; [
    git
    gh
    just
    tmux
    screen
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
    ollama
  ];

  homebrewCasks = [
    "ghostty"
    "tailscale-app"
    "1password"
    "docker"
    "brave-browser"
    "ollama"
  ];

  homebrewBrews = [
    "dockutil"
    "macmon"
  ];
}
