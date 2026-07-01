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
      inherit (lib.lists) filter;
      inherit (lib.modules) mkIf;
      inherit (lib.options) mkEnableOption;
      cfg = config.dsqr.darwin.determinate;
      settings = config.dsqr.nix.settings;
      defaultSubstituters = [
        "https://cache.nixos.org"
        "https://cache.nixos.org/"
      ];
      extraSubstituters = filter (substituter: !(builtins.elem substituter defaultSubstituters)) (
        settings.substituters or [ ]
      );
      determinateSettings =
        removeAttrs settings [
          "substituters"
          "trusted-public-keys"
        ]
        // optionalAttrs (extraSubstituters != [ ]) { "extra-substituters" = extraSubstituters; }
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
