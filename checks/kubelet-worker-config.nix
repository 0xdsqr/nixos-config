{ pkgs, workerConfig }:
let
  cfg = workerConfig.dsqr.nixos.kubeadm;
  overlay = pkgs.writeText "worker-test-overlay.json" (builtins.toJSON {
    inherit (cfg.kubelet.workerHardening) kubeReserved systemReserved podPidsLimit;
    enforceNodeAllocatable = [ "pods" ];
    shutdownGracePeriod = "${toString cfg.kubelet.workerHardening.shutdownGraceSeconds}s";
    shutdownGracePeriodCriticalPods = "${toString cfg.kubelet.workerHardening.criticalShutdownGraceSeconds}s";
  });
  prepare = pkgs.writeShellApplication {
    name = "prepare-kubelet-worker-config";
    runtimeInputs = [ pkgs.coreutils pkgs.yq-go ];
    text = builtins.readFile ../modules/nixos/kubeadm/prepare-worker-config.sh;
  };
in
pkgs.runCommand "kubelet-worker-config-decoder-test" {
  nativeBuildInputs = [ pkgs.coreutils pkgs.gnugrep pkgs.jq pkgs.yq-go ];
} ''
  cp ${../tests/fixtures/kubelet-worker.yaml} base.yaml
  chmod 0600 base.yaml

  # Reproduce the old mixed-YAML/JSON failure with the actual pinned kubelet.
  yq eval-all 'select(fileIndex == 0) * select(fileIndex == 1)' base.yaml ${overlay} > old.yaml
  if ${cfg.packages.kubernetes}/bin/kubelet --config="$PWD/old.yaml" \
    --config-dir="$TMPDIR/intentionally-absent-dropins" >old.log 2>&1; then
    echo 'Expected the old renderer to fail' >&2
    exit 1
  fi
  grep -F 'json parse error' old.log

  ${prepare}/bin/prepare-kubelet-worker-config base.yaml ${overlay} effective.yaml
  jq -e '.podPidsLimit == 4096 and .authentication.anonymous.enabled == false and .authorization.mode == "Webhook"' effective.yaml
  test "$(stat -c %a effective.yaml)" = 600

  # v1.36 loads/decodes --config before visiting --config-dir. This intentional
  # error stops execution before dependencies, listeners, CRI or node registration.
  # --help and --version cannot test decoding: they return before loading config.
  if ${cfg.packages.kubernetes}/bin/kubelet --config="$PWD/effective.yaml" \
    --config-dir="$TMPDIR/intentionally-absent-dropins" >new.log 2>&1; then
    echo 'Expected the deliberate missing drop-in directory to stop startup' >&2
    exit 1
  fi
  grep -F 'failed to merge kubelet configs' new.log
  grep -F 'intentionally-absent-dropins' new.log
  if grep -F 'failed to load kubelet config file' new.log; then exit 1; fi
  mkdir "$out"
  cp old.log new.log "$out/"
''
