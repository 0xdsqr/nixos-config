{ ... }:
{
  perSystem =
    { pkgs, ... }:
    let
      recipients = pkgs.writeText "kubeadm-encryption-recipients.json" (
        builtins.toJSON (import ../../profiles/kubernetes/encryption-recipients.nix)
      );
      package = pkgs.writeShellApplication {
        name = "kubeadm-secrets";
        runtimeInputs = [ pkgs.nodejs ];
        text = ''
          exec node ${./keyring.mjs} ${recipients} ${pkgs.age}/bin/age "$@"
        '';
      };
    in
    {
      packages.kubeadm-secrets = package;
      apps.kubeadm-secrets = {
        type = "app";
        program = "${package}/bin/kubeadm-secrets";
        meta.description = "Prepare an encrypted Kubernetes keyring and copy its recovery record locally";
      };
    };
}
