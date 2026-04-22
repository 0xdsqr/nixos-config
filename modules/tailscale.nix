{
  flake.darwinModules.tailscale = _: { homebrew.casks = [ "tailscale-app" ]; };
  flake.nixosModules.tailscale = _: {
    services.tailscale = {
      enable = true;
      useRoutingFeatures = "client";
    };
  };
}
