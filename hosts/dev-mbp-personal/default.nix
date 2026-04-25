{
  commonModules,
  collectors,
  collectHostNix,
  darwinModules,
  homeModules,
  profiles,
  ...
}:
{
  imports =
    collectors.collectHostModules {
      inherit commonModules homeModules;
      platformModules = darwinModules;
      platform = profiles.devbox.darwin.personal;
      home = profiles.devbox.home.personal;
    }
    ++ collectHostNix { dir = ./.; };

  networking = {
    hostName = "dev-mbp-personal";
    computerName = "dev-mbp-personal";
    localHostName = "dev-mbp-personal";
  };

  meta.system = "aarch64-darwin";
  system.stateVersion = 5;
}
