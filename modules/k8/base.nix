{ config, ... }:

let
  # `config` is the merged result of all modules.
  # We bind our own namespace here so the rest of the file stays readable.
  cfg = config.dsqrK8;
in
{
  config = {
    # `config = { ... };` is the standard NixOS module section that contributes
    # final system settings. Here the custom option is mapped into the real
    # NixOS hostname setting.
    networking.hostName = cfg.hostName;

    # Future example:
    # `environment.etc` writes files into `/etc` declaratively.
    # environment.etc."containerd/config.toml".text = ''
    #   version = 2
    # '';
    #
    # If you manage a service like containerd yourself, you would normally also
    # add a matching `systemd.services.containerd` unit so systemd knows how to
    # start and supervise it.
  };
}
