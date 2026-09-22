let
  keys = import ../dsqr/keys.nix;
in
{
  indigo = {
    file = "profiles/kubernetes/indigo-encryption-keyring.age";
    publicKeys = keys.groups.admins ++ [
      keys.hosts.srv-lx-k8s-indigo-control-01
      keys.hosts.srv-lx-k8s-indigo-control-02
      keys.hosts.srv-lx-k8s-indigo-control-03
    ];
  };
}
