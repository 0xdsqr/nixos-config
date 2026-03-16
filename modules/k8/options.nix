{ lib, ... }:
{
  options.dsqrK8 = {
    hostName = lib.mkOption {
      type = lib.types.str;
      description = "Hostname for Kubernetes control-plane related config.";
    };
  };
}
