{ inputs, ... }:
{
  flake.homeModules.web-browser =
    { pkgs, ... }:
    {
      home.packages = [ inputs.helium.packages.${pkgs.stdenv.hostPlatform.system}.default ];

      home.sessionVariables.BROWSER = "helium";
    };
}
