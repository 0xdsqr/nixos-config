{ ... }:
{
  dsqr.nixos.kubeadm.encryption = {
    enable = true;
    keyringFile = ./indigo-encryption-keyring.age;
    # All current Secret records were verified encrypted, and all three API
    # servers can decrypt them. Reject plaintext reads without changing keys.
    # Activate one API server at a time using explicit manifest regeneration.
    stage = "enforced";
  };
}
