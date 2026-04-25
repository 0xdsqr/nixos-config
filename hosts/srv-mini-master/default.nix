{
  collectors,
  collectHostNix,
  commonModules,
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
      platform = profiles.miniCluster.darwin.default;
      home = profiles.miniCluster.home.default;
    }
    ++ collectHostNix { dir = ./.; };

  meta.system = "aarch64-darwin";

  networking = {
    hostName = "srv-mini-master";
    computerName = "srv-mini-master";
    localHostName = "srv-mini-master";
  };

  system.activationScripts.miniClusterPower.text = ''
    /usr/bin/pmset -a sleep 0 \
      displaysleep 0 \
      disksleep 0 \
      standby 0 \
      autopoweroff 0 \
      womp 1 \
      tcpkeepalive 1 \
      autorestart 1 \
      powernap 1
  '';

  system.stateVersion = 5;
}
