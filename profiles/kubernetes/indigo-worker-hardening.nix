{ lib, ... }: {
  # Current worker size: 4 vCPU / 8 GiB. Override per resource for larger hosts.
  # These reduce Pod allocatable capacity; they do not hard-cap host daemons.
  dsqr.nixos.kubeadm.kubelet.workerHardening = {
    enable = lib.mkDefault true;
    kubeReserved = {
      cpu = lib.mkDefault "250m";
      memory = lib.mkDefault "512Mi";
      ephemeral-storage = lib.mkDefault "1Gi";
      pid = lib.mkDefault "1000";
    };
    systemReserved = {
      cpu = lib.mkDefault "250m";
      memory = lib.mkDefault "512Mi";
      ephemeral-storage = lib.mkDefault "1Gi";
      pid = lib.mkDefault "1000";
    };
    podPidsLimit = lib.mkDefault 4096;
    # Envoy's current 360s termination allowance plus 60s for critical Pods.
    shutdownGraceSeconds = lib.mkDefault 420;
    criticalShutdownGraceSeconds = lib.mkDefault 60;
  };
}
