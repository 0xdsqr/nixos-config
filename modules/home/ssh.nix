{
  flake.homeModules.ssh =
    { self, lib, ... }:
    let
      inherit (lib.attrsets) filterAttrs mapAttrsToList;
      inherit (lib.strings) concatLines;

      hostNameFor = name: host: if host ? sshHost && host.sshHost != null then host.sshHost else name;

      hosts = self.hostDefinitions;

      backupHosts = filterAttrs (_name: host: host.class == "nixos") self.hostDefinitions;

      hostBlocks = mapAttrsToList (name: host: ''
        Host ${name}
          HostName ${hostNameFor name host}
          User dsqr
          IdentityFile ~/.ssh/dsqr_homelab_ed25519
          StrictHostKeyChecking accept-new
      '') hosts;

      backupHostBlocks = mapAttrsToList (name: host: ''
        Host ${name}-backup
          HostName ${hostNameFor name host}
          User backup
          IdentityFile ~/.ssh/dsqr_homelab_ed25519
          StrictHostKeyChecking accept-new
      '') backupHosts;
    in
    {
      home.file.".ssh/config".text = concatLines (
        [
          ''
            Host *
              IdentitiesOnly yes
          ''
        ]
        ++ hostBlocks
        ++ backupHostBlocks
      );
    };
}
