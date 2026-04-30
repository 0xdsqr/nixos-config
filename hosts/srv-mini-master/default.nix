{ self, ... }:
let
  inherit (self.lib)
    commonModules
    darwinModules
    homeModules
    nixLib
    ;
  inherit (nixLib.attrsets) attrValues;
  inherit (nixLib.lists) singleton;

  hostName = "srv-mini-master";

  modules =
    attrValues commonModules ++ attrValues darwinModules ++ singleton (self.lib.mkHomeManagerSharedModule homeModules);
in
{
  flake.hostDefinitions.${hostName} = self.lib.mkHostMeta {
    class = "darwin";
    path = ./.;
    system = "aarch64-darwin";
  };

  flake.darwinConfigurations.${hostName} = self.lib.darwinSystem {
    inherit hostName;

    modules = singleton (
      { ... }:
      {
        imports = modules;

        dsqr.darwin = {
          determinate.enable = true;

          grafana = {
            alloy.enable = true;
            loki = {
              enable = true;
              exo.enable = true;
            };
          };

          desktop = {
            dock.enable = false;
            system.enable = false;
            maccy.enable = false;
          };
        };

        home-manager.users.dsqr.dsqr.home = {
          aws.enable = false;
          exo.enable = true;
          ollama.enable = false;
          neovim.plugins.enable = false;
          nu.integrations.enable = false;
        };

        networking = {
          inherit hostName;
          computerName = hostName;
          localHostName = hostName;
        };

        system.activationScripts.miniClusterPower.text = /* bash */ ''
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
    );
  };
}
