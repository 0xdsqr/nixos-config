{
  flake.darwinModules.determinate =
    {
      config,
      inputs,
      lib,
      ...
    }:
    let
      inherit (lib.attrsets) optionalAttrs removeAttrs;
      inherit (lib.modules) mkIf;
      inherit (lib.options) mkEnableOption;
      cfg = config.dsqr.darwin.determinate;
      settings = config.dsqr.nix.settings;
      determinateSettings =
        removeAttrs settings [ "trusted-public-keys" ]
        // optionalAttrs (settings ? "trusted-public-keys") { "extra-trusted-public-keys" = settings."trusted-public-keys"; };
    in
    {
      imports = [ inputs.determinate.darwinModules.default ];

      options.dsqr.darwin.determinate.enable = mkEnableOption "external Determinate-managed Nix install";

      config = mkIf cfg.enable {
        determinateNix = {
          enable = true;
          customSettings = mkIf config.dsqr.nix.enable determinateSettings;
        };

        ids.gids.nixbld = 350;
      };
    };
}
