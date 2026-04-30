{
  flake.homeModules.network-tools =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (lib.lists) optionals singleton;
      inherit (lib.modules) mkIf;
      inherit (lib.options) mkEnableOption;
      cfg = config.dsqr.home.packages.networkTools;
    in
    {
      options.dsqr.home.packages.networkTools.enable = mkEnableOption "network tooling package bundle" // {
        default = true;
      };

      config = mkIf cfg.enable {
        home.packages = [
          (pkgs.curl.override {
            gnutlsSupport = false;
            opensslSupport = true;
            rustlsSupport = false;
            brotliSupport = true;
            zlibSupport = true;
            zstdSupport = true;
            c-aresSupport = true;
            http2Support = true;
            http3Support = true;
          })
          (pkgs.xh.override { withNativeTls = false; })
          pkgs.dig
          pkgs.doggo
        ]
        ++ optionals pkgs.stdenv.hostPlatform.isDarwin (singleton pkgs.iproute2mac);
      };
    };

  flake.homeModules.packages-kubernetes =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (lib.modules) mkIf;
      inherit (lib.options) mkEnableOption;
      cfg = config.dsqr.home.packages.kubernetes;
    in
    {
      options.dsqr.home.packages.kubernetes.enable = mkEnableOption "Kubernetes package bundle" // {
        default = true;
      };

      config = mkIf cfg.enable {
        home.packages = [
          pkgs.kubectl
          pkgs.kubernetes-helm
        ];
      };
    };

  flake.homeModules.packages-databases =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (lib.lists) singleton;
      inherit (lib.modules) mkIf;
      inherit (lib.options) mkEnableOption;
      cfg = config.dsqr.home.packages.databases;
    in
    {
      options.dsqr.home.packages.databases.enable = mkEnableOption "database package bundle" // {
        default = true;
      };

      config = mkIf cfg.enable { home.packages = singleton pkgs.postgresql; };
    };

  flake.homeModules.packages-node =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (lib.modules) mkIf;
      inherit (lib.options) mkEnableOption;
      cfg = config.dsqr.home.packages.node;
    in
    {
      options.dsqr.home.packages.node.enable = mkEnableOption "Node.js package bundle" // {
        default = true;
      };

      config = mkIf cfg.enable {
        home.packages = [
          pkgs.bun
          pkgs.nodejs_25
        ];
      };
    };

  flake.homeModules.packages-shell-utils =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (lib.modules) mkIf;
      inherit (lib.options) mkEnableOption;
      cfg = config.dsqr.home.packages.shellUtils;
    in
    {
      options.dsqr.home.packages.shellUtils.enable = mkEnableOption "shell utilities package bundle" // {
        default = true;
      };

      config = mkIf cfg.enable {
        home.packages = [
          pkgs.asciinema
          pkgs.eza
          pkgs.fastfetch
          pkgs.fd
          pkgs.fzf
          pkgs.gnumake
          pkgs.jc
          pkgs.jq
          pkgs.moreutils
          pkgs.p7zip
          pkgs.rclone
          pkgs.rsync
          pkgs.sd
          pkgs.timg
          pkgs.tokei
          pkgs.unzip
          pkgs.uutils-coreutils-noprefix
          pkgs.wget
          pkgs.yazi
        ];
      };
    };

  flake.homeModules.packages-containers =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (lib.modules) mkIf;
      inherit (lib.options) mkEnableOption;
      cfg = config.dsqr.home.packages.containers;
    in
    {
      options.dsqr.home.packages.containers.enable = mkEnableOption "container tooling package bundle" // {
        default = true;
      };

      config = mkIf cfg.enable {
        home.packages = [
          pkgs.docker-compose
          pkgs.lazydocker
        ];
      };
    };

  flake.homeModules.packages-media =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (lib.lists) singleton;
      inherit (lib.modules) mkIf;
      inherit (lib.options) mkEnableOption;
      cfg = config.dsqr.home.packages.media;
    in
    {
      options.dsqr.home.packages.media.enable = mkEnableOption "media package bundle" // {
        default = true;
      };

      config = mkIf cfg.enable { home.packages = singleton pkgs.ffmpeg; };
    };

  flake.homeModules.packages-debugging =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (lib.modules) mkIf;
      inherit (lib.options) mkEnableOption;
      cfg = config.dsqr.home.packages.debugging;
    in
    {
      options.dsqr.home.packages.debugging.enable = mkEnableOption "debugging package bundle" // {
        default = true;
      };

      config = mkIf cfg.enable {
        home.packages = [
          pkgs.hyperfine
          pkgs.typos
        ];
      };
    };

  flake.homeModules.packages-signing =
    {
      agenix,
      config,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (lib.modules) mkIf;
      inherit (lib.options) mkEnableOption;
      cfg = config.dsqr.home.packages.signing;
      agenixPackage = agenix.packages.${pkgs.stdenv.hostPlatform.system}.default;
    in
    {
      options.dsqr.home.packages.signing.enable = mkEnableOption "signing package bundle" // {
        default = true;
      };

      config = mkIf cfg.enable {
        home.packages = [
          agenixPackage
          pkgs.gnupg
        ];
      };
    };

  flake.darwinModules.packages =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (lib.lists) singleton;
      inherit (lib.modules) mkIf;
      inherit (lib.options) mkEnableOption;
      cfg = config.dsqr.darwin.packages.screen;
    in
    {
      options.dsqr.darwin.packages.screen.enable = mkEnableOption "screen terminal multiplexer package" // {
        default = true;
      };

      config = mkIf cfg.enable { environment.systemPackages = singleton pkgs.screen; };
    };
}
