{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.dsqr.github-runners;

  # Helper to expand runners with count > 1 into multiple NixOS runner entries
  expandRunners = lib.concatMapAttrs (
    baseName: runnerCfg:
    lib.listToAttrs (
      lib.genList (
        i:
        let
          # hoo-1, hoo-2, etc. (or just "hoo" if count=1)
          instanceName = if runnerCfg.count == 1 then baseName else "${baseName}-${toString (i + 1)}";
        in
        lib.nameValuePair instanceName {
          enable = true;
          name = instanceName;
          tokenFile = config.sops.secrets.${runnerCfg.tokenSecret}.path;
          url = runnerCfg.url;
          extraPackages = runnerCfg.extraPackages;
          extraLabels = runnerCfg.extraLabels ++ [ "nixos" ];
          replace = runnerCfg.replace;
          user = cfg.user;
          group = cfg.group;
          workDir = "${cfg.workDir}/${instanceName}";
        }
        // lib.optionalAttrs (runnerCfg.nodeRuntimes != [ ]) {
          nodeRuntimes = runnerCfg.nodeRuntimes;
        }
      ) runnerCfg.count
    )
  ) cfg.runners;
in
{
  options.dsqr.github-runners = {
    enable = lib.mkEnableOption "GitHub Actions runners";

    user = lib.mkOption {
      type = lib.types.str;
      default = "github-runner";
      description = "User to run GitHub runners as";
    };

    group = lib.mkOption {
      type = lib.types.str;
      default = "github-runner";
      description = "Group for GitHub runners";
    };

    extraGroups = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "docker" ];
      description = "Extra groups for the runner user";
    };

    sopsFile = lib.mkOption {
      type = lib.types.path;
      description = "Path to sops secrets file containing runner tokens";
    };

    workDir = lib.mkOption {
      type = lib.types.path;
      default = "/var/lib/github-runners";
      description = "Base directory for runner work directories";
    };

    runners = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule {
          options = {
            url = lib.mkOption {
              type = lib.types.str;
              example = "https://github.com/myorg/myrepo";
              description = "GitHub repository or organization URL";
            };

            tokenSecret = lib.mkOption {
              type = lib.types.str;
              example = "github_runners/myrepo/token";
              description = "Sops secret path for the runner token";
            };

            extraPackages = lib.mkOption {
              type = lib.types.listOf lib.types.package;
              default = with pkgs; [ git ];
              description = "Extra packages available to the runner";
            };

            extraLabels = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              default = [ ];
              example = [
                "nix"
                "docker"
                "x86_64-linux"
              ];
              description = "Extra labels for the runner";
            };

            replace = lib.mkOption {
              type = lib.types.bool;
              default = true;
              description = "Replace existing runner with same name";
            };

            nodeRuntimes = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              default = [ ];
              example = [ "node20" ];
              description = "Node.js runtimes to make available";
            };

            count = lib.mkOption {
              type = lib.types.int;
              default = 1;
              example = 4;
              description = "Number of parallel runner instances for this repo";
            };
          };
        }
      );
      default = { };
      description = "Attribute set of runner configurations";
    };
  };

  config = lib.mkIf cfg.enable {
    # Create user and group
    users.users.${cfg.user} = {
      isSystemUser = true;
      home = cfg.workDir;
      extraGroups = cfg.extraGroups;
      createHome = true;
      group = cfg.group;
      description = "GitHub Actions runner system user";
    };

    users.groups.${cfg.group} = { };

    # Setup sops
    sops.defaultSopsFile = lib.mkDefault cfg.sopsFile;
    sops.age.keyFile = lib.mkDefault "/var/lib/sops-nix/key.txt";

    # Create sops secrets for each runner (one token per repo, shared by instances)
    sops.secrets = lib.mapAttrs' (
      name: runnerCfg:
      lib.nameValuePair runnerCfg.tokenSecret {
        mode = "0400";
        owner = cfg.user;
        group = cfg.group;
      }
    ) cfg.runners;

    # Configure each runner using built-in NixOS service
    services.github-runners = lib.mapAttrs (
      name: runnerCfg:
      {
        enable = true;
        inherit name;
        tokenFile = config.sops.secrets.${runnerCfg.tokenSecret}.path;
        url = runnerCfg.url;
        extraPackages = runnerCfg.extraPackages;
        extraLabels = runnerCfg.extraLabels ++ [ "nixos" ];
        replace = runnerCfg.replace;
        user = cfg.user;
        group = cfg.group;
        # workDir = "${cfg.workDir}/${name}";
      }
      // lib.optionalAttrs (runnerCfg.nodeRuntimes != [ ]) {
        nodeRuntimes = runnerCfg.nodeRuntimes;
      }
    ) cfg.runners;

    # Allow runner to use nix for nix-based workflows
    nix.settings.trusted-users = [ cfg.user ];
  };
}
