{
  darwinModules,
  homeModules,
  lib,
}:
let
  inherit (lib.attrsets) attrNames;
  inherit (lib.lists) elem;

  removeNames = names: excluded: builtins.filter (name: !(elem name excluded)) names;

  devboxDarwinMinimal = [
    "dsqr-user"
    "homebrew"
    "hostname"
    "packages"
    "shells"
    "sudo"
    "tailscale"
  ];

  devboxDarwinStandard = devboxDarwinMinimal ++ [
    "bat"
    "clipboard"
    "desktop-personal"
    "google-chrome"
    "helium"
  ];

  devboxDarwinPersonal = removeNames (attrNames darwinModules) [
    "desktop-stablecore"
    "monitoring-alloy-base"
    "monitoring-alloy-loki"
    "signal"
    "slack"
    "zoom"
  ];

  devboxHomeMinimal = [
    "bat"
    "btop"
    "git"
    "nushell"
    "packages-shell-utils"
    "ripgrep"
    "ssh"
    "starship"
    "xdg"
    "zoxide"
  ];

  devboxHomeStandard = devboxHomeMinimal ++ [
    "claude-code"
    "codex"
    "direnv"
    "ghostty"
    "neovim"
    "network-tools"
    "opencode"
    "packages-containers"
    "packages-debugging"
    "packages-kubernetes"
    "packages-signing"
    "pi"
    "tailscale"
    "web-browser"
  ];

  devboxHomePersonal = removeNames (attrNames homeModules) [
    "carapace"
    "cinny"
    "exo"
    "ollama"
    "signal"
  ];

  miniClusterDarwinDefault = [
    "dsqr-user"
    "homebrew"
    "hostname"
    "shells"
    "sudo"
    "tailscale"
  ];

  miniClusterDarwinMonitoring = miniClusterDarwinDefault ++ [
    "monitoring-alloy-base"
    "monitoring-alloy-loki"
  ];

  miniClusterHomeDefault = [
    "ghostty"
    "git"
    "neovim"
    "network-tools"
    "nushell"
    "ripgrep"
    "ssh"
    "starship"
    "tailscale"
    "xdg"
    "zoxide"
  ];

  miniClusterHomeExo = miniClusterHomeDefault ++ [ "exo" ];
in
{
  devbox = {
    darwin = {
      minimal = devboxDarwinMinimal;
      standard = devboxDarwinStandard;
      personal = devboxDarwinPersonal;
    };

    home = {
      minimal = devboxHomeMinimal;
      standard = devboxHomeStandard;
      personal = devboxHomePersonal;
    };
  };

  miniCluster = {
    darwin = {
      default = miniClusterDarwinDefault;
      monitoring = miniClusterDarwinMonitoring;
    };

    home = {
      default = miniClusterHomeDefault;
      exo = miniClusterHomeExo;
    };
  };
}
