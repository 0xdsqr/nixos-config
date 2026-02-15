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
    uv
    rustup
    nodejs_24
    ollama

    # Python with exo for distributed LLM cluster
    (python312.withPackages (ps: with ps; [
      pip
      virtualenv
    ]))
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
