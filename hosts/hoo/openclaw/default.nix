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
  mkWorkspaceDocsActivation =
    {
      workspaceDir,
      docDir,
      extraDocNames ? [ ],
    }:
    let
      docNames = builtins.filter (docName: builtins.pathExists (docDir + "/${docName}")) (
        baseWorkspaceDocNames ++ optionalWorkspaceDocNames ++ extraDocNames
      );
      seedCommands = builtins.concatStringsSep "\n" (
        map (docName: ''
          target="$HOME/${workspaceDir}/${docName}"
          if [ ! -e "$target" ] || [ -L "$target" ]; then
            rm -f "$target"
            cp ${docDir + "/${docName}"} "$target"
            chmod u+rw "$target"
          fi
        '') docNames
      );
    in
    ''
      ${seedCommands}
    '';
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
      { lib, ... }:
      {
        imports = [
          (_: {
            _module.args = {
              inherit
                commonInstanceConfig
                mkWorkspaceDocsActivation
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

        home.activation = {
          openclaw-hoo-workspace-docs = lib.hm.dag.entryAfter [ "linkGeneration" ] (mkWorkspaceDocsActivation {
            workspaceDir = ".openclaw-hoo/workspace";
            docDir = ./documents/noctua;
          });
          openclaw-vanilla-workspace-docs = lib.hm.dag.entryAfter [ "linkGeneration" ] (mkWorkspaceDocsActivation {
            workspaceDir = ".openclaw-vanilla/workspace";
            docDir = ./documents/vanilla;
          });
        };
      }
    )
  ];
}
