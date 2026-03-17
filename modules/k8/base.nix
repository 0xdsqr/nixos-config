{ config, ... }:

let
  cfg = config.dsqrK8;
in
{
  config = {
    networking.hostName = cfg.hostName;
  };
}
