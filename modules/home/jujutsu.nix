{
  flake.homeModules.jujutsu =
    { config, ... }:
    {
      programs.jujutsu = {
        enable = true;
        settings = {
          user = {
            inherit (config.programs.git.settings.user) name;
            inherit (config.programs.git.settings.user) email;
          };
        };
      };
    };
}
