let
  inventory = import ../../profiles/kubernetes/indigo-backup.nix;
in
{
  dsqr.nixos.etcdBackup.source = {
    enable = true;
    clusterName = "indigo";
    inherit (inventory) collectorAddress collectorPublicKey recoveryRecipients;
  };
}
