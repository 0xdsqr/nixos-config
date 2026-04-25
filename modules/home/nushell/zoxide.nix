{
  flake.homeModules.zoxide = _: {
    programs.zoxide = {
      enable = true;
      enableNushellIntegration = true;
      options = [
        "--cmd"
        "cd"
      ];
    };
  };
}
