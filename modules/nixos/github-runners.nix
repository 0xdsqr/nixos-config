{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.dsqr.github-runners;

  nodeRuntimeType =
    with lib.types;
    nonEmptyListOf (enum [
      "node20"
      "node24"
    ]);

  runnerType = _: {
    options = {
      url = lib.mkOption {
        type = lib.types.str;
        example = "https://github.com/myuser/myrepo";
        description = "GitHub repository URL for this runner.";
      };

      tokenSecret = lib.mkOption {
        type = lib.types.str;
        example = "github_runners/myrepo/token";
        description = "SOPS secret path containing the runner PAT.";
      };

      count = lib.mkOption {
        type = lib.types.ints.positive;
        default = 1;
        example = 2;
        description = "Number of runner instances to register for this repository.";
      };

      extraPackages = lib.mkOption {
        type = lib.types.listOf lib.types.package;
        default = [ ];
        description = "Extra packages exposed to workflow jobs.";
      };

      extraLabels = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        example = [
          "nix"
          "docker"
          "node24"
        ];
        description = "Extra capability labels for the runner.";
      };

      replace = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Replace any existing runner with the same name.";
      };

      tokenType = lib.mkOption {
        type = lib.types.enum [
          "auto"
          "access"
          "registration"
        ];
        default = "access";
        description = "Authentication mode used to register the runner.";
      };

      ephemeral = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Register the runner as ephemeral so it handles one job per lifecycle.";
      };

      noDefaultLabels = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Disable GitHub's default self-hosted labels.";
      };

      docker = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Grant this runner access to the local Docker daemon.";
      };

      nodeRuntimes = lib.mkOption {
        type = lib.types.nullOr nodeRuntimeType;
        default = null;
        example = [ "node24" ];
        description = "Node runtimes bundled into the runner package for JavaScript actions.";
      };

      extraEnvironment = lib.mkOption {
        type = lib.types.attrs;
        default = { };
        description = "Extra environment variables exposed to the runner service.";
      };

      serviceOverrides = lib.mkOption {
        type = lib.types.attrs;
        default = { };
        description = "Additional systemd service overrides for this runner.";
      };

      workDir = lib.mkOption {
        type = with lib.types; nullOr str;
        default = null;
        description = "Override the default per-instance work directory.";
      };
    };
  };

  runtimeLabels = [
    "nix"
    "nixos"
    pkgs.stdenv.hostPlatform.system
  ];

  mkInstance =
    baseName: runnerCfg: index:
    let
      suffix = lib.optionalString (runnerCfg.count > 1) "-${toString index}";
      instanceName = "${baseName}${suffix}";
      workDir =
        if runnerCfg.workDir != null then
          if runnerCfg.count == 1 then runnerCfg.workDir else "${runnerCfg.workDir}${suffix}"
        else
          "${cfg.workDir}/${instanceName}";

      dockerOverrides = lib.optionalAttrs runnerCfg.docker {
        SupplementaryGroups = (runnerCfg.serviceOverrides.SupplementaryGroups or [ ]) ++ [ "docker" ];
      };
    in
    lib.nameValuePair instanceName (
      {
        enable = true;
        tokenFile = config.sops.secrets.${runnerCfg.tokenSecret}.path;
        inherit (runnerCfg) url;
        inherit (runnerCfg) extraPackages;
        inherit (runnerCfg) replace;
        inherit (runnerCfg) tokenType;
        inherit (runnerCfg) ephemeral;
        inherit (runnerCfg) noDefaultLabels;
        inherit (runnerCfg) extraEnvironment;
        inherit workDir;
        name = instanceName;
        inherit (cfg) user;
        inherit (cfg) group;
        extraLabels = lib.unique (
          runtimeLabels ++ runnerCfg.extraLabels ++ lib.optional runnerCfg.docker "docker"
        );
        serviceOverrides = lib.recursiveUpdate runnerCfg.serviceOverrides dockerOverrides;
      }
      // lib.optionalAttrs (runnerCfg.nodeRuntimes != null) {
        inherit (runnerCfg) nodeRuntimes;
      }
    );

  expandedRunners = lib.concatMapAttrs (
    name: runnerCfg:
    builtins.listToAttrs (map (index: mkInstance name runnerCfg index) (lib.range 1 runnerCfg.count))
  ) cfg.runners;

  workDirs = lib.mapAttrsToList (_: runnerCfg: runnerCfg.workDir) expandedRunners;
in
{
  options.dsqr.github-runners = {
    enable = lib.mkEnableOption "GitHub Actions runners";

    user = lib.mkOption {
      type = lib.types.str;
      default = "github-runner";
      description = "User to run GitHub runners as.";
    };

    group = lib.mkOption {
      type = lib.types.str;
      default = "github-runner";
      description = "Group for GitHub runners.";
    };

    sopsFile = lib.mkOption {
      type = lib.types.path;
      description = "Path to the SOPS file containing runner PATs.";
    };

    workDir = lib.mkOption {
      type = lib.types.path;
      default = "/var/lib/github-runners";
      description = "Base directory for runner work directories.";
    };

    runners = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule runnerType);
      default = { };
      description = "Repository runner definitions.";
    };
  };

  config = lib.mkIf cfg.enable {
    users.users.${cfg.user} = {
      isSystemUser = true;
      home = cfg.workDir;
      createHome = true;
      inherit (cfg) group;
      description = "GitHub Actions runner system user";
    };

    users.groups.${cfg.group} = { };

    sops.defaultSopsFile = lib.mkDefault cfg.sopsFile;
    sops.age.keyFile = lib.mkDefault "/var/lib/sops-nix/key.txt";

    sops.secrets = lib.mapAttrs' (
      _name: runnerCfg:
      lib.nameValuePair runnerCfg.tokenSecret {
        mode = "0400";
        owner = cfg.user;
        inherit (cfg) group;
      }
    ) cfg.runners;

    systemd.tmpfiles.rules = [
      "d ${cfg.workDir} 0750 ${cfg.user} ${cfg.group} -"
    ]
    ++ map (dir: "d ${dir} 0750 ${cfg.user} ${cfg.group} -") workDirs;

    services.github-runners = expandedRunners;

    nix.settings.trusted-users = [ cfg.user ];
  };
}
