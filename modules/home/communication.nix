{
  flake.homeModules.discord =
    { lib, pkgs, ... }:
    {
      home.packages = lib.optionals pkgs.stdenv.hostPlatform.isLinux [ pkgs.discord ];
    };

  flake.homeModules.signal =
    { lib, pkgs, ... }:
    {
      home.packages = lib.optionals pkgs.stdenv.hostPlatform.isLinux [ pkgs.signal-desktop ];
    };

  flake.homeModules.cinny =
    { lib, pkgs, ... }:
    {
      home.packages = lib.optionals pkgs.stdenv.hostPlatform.isLinux [ pkgs.cinny-desktop ];
    };

  flake.homeModules.thunderbird =
    { lib, pkgs, ... }:
    {
      home.packages = [ pkgs.thunderbird ];

      xdg.mimeApps.defaultApplications = lib.mkIf pkgs.stdenv.hostPlatform.isLinux (
        builtins.listToAttrs (
          map
            (mime: {
              name = mime;
              value = [ "thunderbird.desktop" ];
            })
            [
              "message/rfc822"
              "x-scheme-handler/mailto"
              "text/calendar"
              "text/x-vcard"
            ]
        )
      );
    };
}
