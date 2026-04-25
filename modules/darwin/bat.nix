{
  flake.darwinModules.bat =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (lib.meta) getExe;
      inherit (lib.modules) mkAfter;
    in
    {
      system.activationScripts.script.text = mkAfter ''
        ${config.system.activationScripts.bat.text}
      '';

      system.activationScripts.bat.text = ''
        echo "refreshing bat cache..."
        ${getExe pkgs.bat} cache --build
      '';
    };
}
