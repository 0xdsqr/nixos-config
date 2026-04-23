{ config, ... }:
let
  openclawEnvFile = config.age.secrets.openclawEnv.path;
in
{
  dsqr.home.imports = [
    (
      { pkgs, ... }:
      {
        home.packages = [
          (pkgs.writeShellScriptBin "openclaw-hoo" ''
            set -euo pipefail
            set -a
            source ${openclawEnvFile}
            set +a
            export OPENCLAW_CONFIG_PATH="/home/dsqr/.openclaw-hoo/openclaw.json"
            export OPENCLAW_STATE_DIR="/home/dsqr/.openclaw-hoo"
            exec openclaw "$@"
          '')
          (pkgs.writeShellScriptBin "openclaw-vanilla" ''
            set -euo pipefail
            set -a
            source ${openclawEnvFile}
            set +a
            export OPENCLAW_CONFIG_PATH="/home/dsqr/.openclaw-vanilla/openclaw.json"
            export OPENCLAW_STATE_DIR="/home/dsqr/.openclaw-vanilla"
            exec openclaw "$@"
          '')
        ];

        programs.nushell.shellAliases = {
          och = "openclaw-hoo";
          ocv = "openclaw-vanilla";
        };

        programs.zsh.shellAliases = {
          och = "openclaw-hoo";
          ocv = "openclaw-vanilla";
        };
      }
    )
  ];
}
