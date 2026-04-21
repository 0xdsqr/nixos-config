{ self, lib, ... }:
let
  inherit (lib.attrsets) filterAttrs mapAttrsToList;
  inherit (lib.lists) singleton;
  inherit (lib.strings) concatLines;

  hosts = filterAttrs (_: host: host ? sshHost && host.sshHost != null) self.hostDefinitions;

  hostBlocks = mapAttrsToList (
    name: host:
    ''
      Host ${name}
        HostName ${host.sshHost}
        User dsqr
        IdentityFile ~/.ssh/dsqr_homelab_ed25519
        StrictHostKeyChecking accept-new
    ''
  ) hosts;
in
{
  home.file.".ssh/config".text = concatLines (
    singleton ''
      Host *
        IdentitiesOnly yes
    ''
    ++ hostBlocks
  );
}
