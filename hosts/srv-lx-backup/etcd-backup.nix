let
  inventory = import ../../profiles/kubernetes/indigo-backup.nix;
in
{
  dsqr.nixos.etcdBackup.collector = {
    enable = true;
    jobs.indigo = {
      inherit (inventory) sourceAddress sourceHostPublicKey;
    };
  };
}
