{
  pkgs,
  lib,
  exclude_packages ? [ ],
}:
let
  # Essential Hyprland packages - cannot be excluded (Linux only)
  hyprlandPackages =
    with pkgs;
    lib.optionals pkgs.stdenv.hostPlatform.isLinux [
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
    ++ lib.optionals pkgs.stdenv.hostPlatform.isLinux [
      libnotify
      nautilus
      blueberry
      clipse
    ];

  # Discretionary packages - can be excluded by user
  discretionaryPackages =
    with pkgs;
    [
      # TUIs (cross-platform)
      lazygit
      lazydocker
      btop
      fastfetch

      # Development tools (CLI only)
      gh
      cachix

      # Containers
      docker-compose
      ffmpeg
    ]
    ++ lib.optionals pkgs.stdenv.hostPlatform.isLinux [
      # Linux-specific packages + all GUI apps (Darwin uses casks)
      powertop
      chromium
      obsidian
      vlc
      signal-desktop
      github-desktop
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
