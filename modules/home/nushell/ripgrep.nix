{
  flake.homeModules.ripgrep = _: {
    programs.ripgrep = {
      enable = true;
      arguments = [ "--smart-case" ];
    };
  };
}
