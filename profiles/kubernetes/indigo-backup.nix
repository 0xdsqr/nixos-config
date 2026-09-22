let
  keys = import ../dsqr/keys.nix;
in
{
  sourceAddress = "100.102.143.47";
  sourceHostPublicKey = keys.hosts.srv-lx-k8s-indigo-control-01;
  collectorAddress = "100.71.152.103";
  collectorPublicKey = keys.hosts.srv-lx-backup;
  recoveryRecipients = keys.groups.admins;
}
