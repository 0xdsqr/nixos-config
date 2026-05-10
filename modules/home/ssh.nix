{
  flake.homeModules.ssh =
    {
      config,
      self,
      lib,
      ...
    }:
    let
      inherit (lib.attrsets) filterAttrs mapAttrsToList;
      inherit (lib.lists) optionals;
      inherit (lib.modules) mkIf;
      inherit (lib.options) mkEnableOption mkOption;
      inherit (lib.strings) concatLines optionalString;
      inherit (lib.types) lines;

      cfg = config.dsqr.home.ssh;

      hostNameFor = name: host: if host ? sshHost && host.sshHost != null then host.sshHost else name;

      hosts = self.hostDefinitions;

      backupHosts = filterAttrs (_name: host: host.class == "nixos") self.hostDefinitions;

      hostBlocks = mapAttrsToList (name: host: /* sshconfig */ ''
        Host ${name}
          HostName ${hostNameFor name host}
          User dsqr
          IdentityFile ~/.ssh/dsqr_homelab_ed25519
          StrictHostKeyChecking accept-new
      '') hosts;

      backupHostBlocks = mapAttrsToList (name: host: /* sshconfig */ ''
        Host ${name}-backup
          HostName ${hostNameFor name host}
          User backup
          IdentityFile ~/.ssh/dsqr_homelab_ed25519
          StrictHostKeyChecking accept-new
      '') backupHosts;
    in
    {
      options.dsqr.home.ssh = {
        enable = mkEnableOption "SSH configuration" // {
          default = true;
        };

        defaults.enable = mkEnableOption "base SSH defaults block" // {
          default = true;
        };

        homelab.enable = mkEnableOption "generated homelab SSH host entries" // {
          default = true;
        };

        extraConfig = mkOption {
          type = lines;
          default = "";
          description = "Additional SSH config appended after the generated homelab entries.";
        };
      };

      config = mkIf cfg.enable {
        home.file.".ssh/config".text =
          concatLines (
            optionals cfg.defaults.enable [
              /* sshconfig */ ''
                Host *
                  IdentitiesOnly yes
              ''
            ]
            ++ optionals cfg.homelab.enable (hostBlocks ++ backupHostBlocks)
          )
          + optionalString (cfg.extraConfig != "") ("\n" + cfg.extraConfig);
      };
    };
}
