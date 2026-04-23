{ config, nix-openclaw, ... }:
let
  openclawEnvFile = config.age.secrets.openclawEnv.path;
  pluginDefs = import ./plugins.nix;
  commonInstanceConfig = import ./models.nix;
  mkWorkspaceDocs =
    workspaceDir: docDir:
    builtins.listToAttrs (
      map
        (name: {
          name = "${workspaceDir}/${name}";
          value = {
            source = docDir + "/${name}";
            force = true;
          };
        })
        [
          "AGENTS.md"
          "SOUL.md"
          "TOOLS.md"
        ]
    );
in
{
  age.secrets.openclawEnv = {
    file = ./openclaw.env.age;
    owner = "dsqr";
    mode = "0400";
  };

  users.users.dsqr.linger = true;

  dsqr.home.imports = [
    nix-openclaw.homeManagerModules.openclaw
    (
      { ... }:
      {
        imports = [
          (_: {
            _module.args = {
              inherit
                commonInstanceConfig
                mkWorkspaceDocs
                openclawEnvFile
                pluginDefs
                ;
            };
          })
          ./hoo.nix
          ./vanilla.nix
        ];

        programs.openclaw = {
          # Avoid user profile PATH collisions when plugin binaries overlap with
          # tools that the base OpenClaw package already exposes.
          exposePluginPackages = false;

          # We want different persona docs per instance, so we do not use the
          # current global `programs.openclaw.documents` option here.
          documents = null;
          inherit (pluginDefs) bundledPlugins;
        };
      }
    )
  ];
}
