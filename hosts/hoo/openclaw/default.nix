{
  config,
  nix-openclaw,
  pkgs,
  ...
}:
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
  mkWorkspaceSkillsActivation =
    { workspaceDir }:
    ''
      skills_root="$HOME/${workspaceDir}/skills"
      if [ -d "$skills_root" ]; then
        for skill_dir in "$skills_root"/*; do
          [ -e "$skill_dir" ] || continue
          if [ -L "$skill_dir" ]; then
            skill_src="$(readlink -f "$skill_dir")"
            rm -f "$skill_dir"
            mkdir -p "$skill_dir"
            cp -R "$skill_src"/. "$skill_dir"/
            chmod -R u+rw "$skill_dir" || true
          elif [ -L "$skill_dir/SKILL.md" ]; then
            skill_src="$(readlink -f "$skill_dir/SKILL.md")"
            rm -f "$skill_dir/SKILL.md"
            cp "$skill_src" "$skill_dir/SKILL.md"
            chmod u+rw "$skill_dir/SKILL.md"
          fi
        done
      fi
    '';
  mkOpenclawCli =
    {
      name,
      configPath,
      stateDir,
    }:
    pkgs.writeShellScriptBin name ''
      set -euo pipefail
      set -a
      source ${openclawEnvFile}
      set +a
      export OPENCLAW_CONFIG_PATH="${configPath}"
      export OPENCLAW_STATE_DIR="${stateDir}"
      exec openclaw "$@"
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

        home.packages = [
          (mkOpenclawCli {
            name = "openclaw-hoo";
            configPath = "/home/dsqr/.openclaw-hoo/openclaw.json";
            stateDir = "/home/dsqr/.openclaw-hoo";
          })
          (mkOpenclawCli {
            name = "openclaw-vanilla";
            configPath = "/home/dsqr/.openclaw-vanilla/openclaw.json";
            stateDir = "/home/dsqr/.openclaw-vanilla";
          })
        ];

        home.activation = {
          openclaw-hoo-workspace-docs = lib.hm.dag.entryAfter [ "linkGeneration" ] (mkWorkspaceDocsActivation {
            workspaceDir = ".openclaw-hoo/workspace";
            docDir = ./documents/noctua;
          });
          openclaw-vanilla-workspace-docs = lib.hm.dag.entryAfter [ "linkGeneration" ] (mkWorkspaceDocsActivation {
            workspaceDir = ".openclaw-vanilla/workspace";
            docDir = ./documents/vanilla;
          });
          openclaw-hoo-workspace-skills = lib.hm.dag.entryAfter [ "linkGeneration" ] (mkWorkspaceSkillsActivation {
            workspaceDir = ".openclaw-hoo/workspace";
          });
          openclaw-vanilla-workspace-skills = lib.hm.dag.entryAfter [ "linkGeneration" ] (mkWorkspaceSkillsActivation {
            workspaceDir = ".openclaw-vanilla/workspace";
          });
        };
      }
    )
  ];
}
