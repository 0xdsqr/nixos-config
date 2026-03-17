{ lib, ... }:
{
  options.dsqrK8 = {
    # `options` declares custom settings that other modules or machine files are
    # allowed to set. This creates `config.dsqrK8.hostName`.
    hostName = lib.mkOption {
      type = lib.types.str;
      description = "Hostname for Kubernetes control-plane related config.";
    };
  };
}
