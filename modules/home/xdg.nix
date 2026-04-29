{
  flake.homeModules.xdg =
    { config, lib, ... }:
    let
      inherit (lib.lists) singleton;
      inherit (lib.modules) mkIf;
      inherit (lib.options) mkEnableOption;

      cfg = config.dsqr.home.xdg;
    in
    {
      options.dsqr.home.xdg.enable = mkEnableOption "XDG directories and history locations" // {
        default = true;
      };

      config = mkIf cfg.enable {
        xdg.enable = true;
        home.preferXdgDirectories = true;

        home.sessionVariables = {
          AWS_CONFIG_FILE = "${config.xdg.configHome}/aws/config";
          AWS_SHARED_CREDENTIALS_FILE = "${config.xdg.configHome}/aws/credentials";
          CARGO_HOME = "${config.xdg.dataHome}/cargo";
          GOPATH = "${config.xdg.dataHome}/go";
          LESSHISTFILE = "${config.xdg.stateHome}/less/history";
          NODE_REPL_HISTORY = "${config.xdg.stateHome}/node/history";
          PYTHON_HISTORY = "${config.xdg.stateHome}/python/history";
          RUSTUP_HOME = "${config.xdg.dataHome}/rustup";
          SQLITE_HISTORY = "${config.xdg.stateHome}/sqlite/history";
        };

        home.sessionPath = [
          "${config.xdg.dataHome}/cargo/bin"
          "${config.xdg.dataHome}/go/bin"
        ];

        home.activation.ensureXdgToolingPaths = lib.hm.dag.entryAfter (singleton "writeBoundary") /* bash */ ''
          mkdir -p \
            "${config.xdg.configHome}/aws" \
            "${config.xdg.configHome}/ripgrep" \
            "${config.xdg.dataHome}/cargo/bin" \
            "${config.xdg.dataHome}/go/bin" \
            "${config.xdg.dataHome}/rustup" \
            "${config.xdg.stateHome}/less" \
            "${config.xdg.stateHome}/node" \
            "${config.xdg.stateHome}/python" \
            "${config.xdg.stateHome}/sqlite"

          touch \
            "${config.xdg.configHome}/aws/credentials" \
            "${config.xdg.configHome}/ripgrep/config" \
            "${config.xdg.stateHome}/less/history" \
            "${config.xdg.stateHome}/node/history" \
            "${config.xdg.stateHome}/python/history" \
            "${config.xdg.stateHome}/sqlite/history"
        '';
      };
    };
}
