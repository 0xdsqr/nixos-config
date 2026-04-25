{
  flake.homeModules.network-tools =
    { lib, pkgs, ... }:
    {
      home.packages = [
        (pkgs.curl.override {
          gnutlsSupport = false;
          opensslSupport = true;
          wolfsslSupport = false;
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
      ++ lib.optionals pkgs.stdenv.hostPlatform.isDarwin [ pkgs.iproute2mac ];
    };

  flake.homeModules.packages-kubernetes =
    { pkgs, ... }:
    {
      home.packages = [
        pkgs.kubectl
        pkgs.kubernetes-helm
      ];
    };

  flake.homeModules.packages-databases =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.postgresql ];
    };

  flake.homeModules.packages-node =
    { pkgs, ... }:
    {
      home.packages = [
        pkgs.bun
        pkgs.nodejs_25
      ];
    };

  flake.homeModules.packages-shell-utils =
    { pkgs, ... }:
    {
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

  flake.homeModules.packages-containers =
    { pkgs, ... }:
    {
      home.packages = [
        pkgs.docker-compose
        pkgs.lazydocker
      ];
    };

  flake.homeModules.packages-media =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.ffmpeg ];
    };

  flake.homeModules.packages-debugging =
    { pkgs, ... }:
    {
      home.packages = [
        pkgs.hyperfine
        pkgs.typos
      ];
    };

  flake.homeModules.packages-signing =
    { agenix, pkgs, ... }:
    let
      agenixPackage = agenix.packages.${pkgs.stdenv.hostPlatform.system}.default;
    in
    {
      home.packages = [
        agenixPackage
        pkgs.gnupg
      ];
    };

  flake.darwinModules.packages =
    { pkgs, ... }:
    {
      environment.systemPackages = [ pkgs.screen ];
    };
}
