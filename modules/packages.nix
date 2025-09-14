{
  pkgs,
  lib,
  exclude_packages ? [ ],
}:
let
  # Essential Hyprland packages - cannot be excluded (Linux only)
  hyprlandPackages =
    with pkgs;
    lib.optionals (lib.meta.isLinux pkgs.stdenv.hostPlatform) [
      hyprshot
      hyprpicker
      hyprsunset
      brightnessctl
      pamixer
      playerctl
      gnome-themes-extra
      pavucontrol
    ];

  # Essential system packages - cannot be excluded
  systemPackages =
    with pkgs;
    [
      git
      vim
      alejandra
      fzf
      zoxide
      ripgrep
      eza
      fd
      curl
      unzip
      wget
      gnumake
    ]
    ++ lib.optionals (lib.meta.isLinux pkgs.stdenv.hostPlatform) [
      libnotify
      nautilus
      blueberry
      clipse
    ];

  # Discretionary packages - can be excluded by user
  discretionaryPackages =
    with pkgs;
    [
      # TUIs
      lazygit
      lazydocker
      btop
      powertop
      fastfetch

      # GUIs
      chromium
      obsidian
      vlc
      signal-desktop

      # Development tools
      github-desktop
      gh
      cachix

      # Containers
      docker-compose
      ffmpeg
    ]
    ++ lib.optionals (lib.meta.isLinux pkgs.stdenv.hostPlatform) [
      spotify
      typora
      dropbox
    ];

  # Only allow excluding discretionary packages to prevent breaking the system
  filteredDiscretionaryPackages = lib.lists.subtractLists exclude_packages discretionaryPackages;
  allSystemPackages = hyprlandPackages ++ systemPackages ++ filteredDiscretionaryPackages;
in
{
  # Regular packages
  systemPackages = allSystemPackages;

  homePackages = with pkgs; [
  ];
}
