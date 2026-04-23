{ config, nix-openclaw, ... }:
let
  openclawEnvFile = config.age.secrets.openclawEnv.path;
  pluginDefs = import ./plugins.nix;
  commonInstanceConfig = import ./models.nix;
  baseWorkspaceDocNames = [
    "AGENTS.md"
    "SOUL.md"
    "TOOLS.md"
  ];
  optionalWorkspaceDocNames = [
    "IDENTITY.md"
    "USER.md"
    "LORE.md"
    "HEARTBEAT.md"
    "PROMPTING-EXAMPLES.md"
    "MEMORY.md"
    "BOOTSTRAP.md"
  ];
  mkWorkspaceDocs =
    {
      workspaceDir,
      docDir,
      extraDocNames ? [ ],
    }:
    let
      docNames = builtins.filter (name: builtins.pathExists (docDir + "/${name}")) (
        baseWorkspaceDocNames ++ optionalWorkspaceDocNames ++ extraDocNames
      );
    in
    builtins.listToAttrs (
      map (name: {
        name = "${workspaceDir}/${name}";
        value = {
          source = docDir + "/${name}";
          force = true;
        };
      }) docNames
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
