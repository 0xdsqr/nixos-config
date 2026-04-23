{
  flake.homeModules.ssh =
    { self, lib, ... }:
    let
      inherit (lib.attrsets) filterAttrs mapAttrsToList;
      inherit (lib.lists) singleton;
      inherit (lib.strings) concatLines;

      hosts = filterAttrs (_: host: host ? sshHost && host.sshHost != null) self.hostDefinitions;

      backupHosts = filterAttrs (
        name: host:
        host ? sshHost
        && host.sshHost != null
        && builtins.hasAttr name self.nixosConfigurations
        && self.nixosConfigurations.${name}.config.users.users ? backup
      ) self.hostDefinitions;

      hostBlocks = mapAttrsToList (name: host: ''
        Host ${name}
          HostName ${host.sshHost}
          User dsqr
          IdentityFile ~/.ssh/dsqr_homelab_ed25519
          StrictHostKeyChecking accept-new
      '') hosts;

      backupHostBlocks = mapAttrsToList (name: host: ''
        Host ${name}-backup
          HostName ${host.sshHost}
          User backup
          IdentityFile ~/.ssh/dsqr_homelab_ed25519
          StrictHostKeyChecking accept-new
      '') backupHosts;
    in
    {
      home.file.".ssh/config".text = concatLines (
        singleton ''
          Host *
            IdentitiesOnly yes
        ''
        ++ hostBlocks
        ++ backupHostBlocks
      );
    };
}
