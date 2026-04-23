let
  commonPlugins = [
    {
      source = "github:openclaw/nix-steipete-tools?dir=tools/summarize";
      config = {
        env = {
          OPENAI_API_KEY = "/run/agenix/openclawEnv";
        };
      };
    }
    {
      source = "github:openclaw/nix-steipete-tools?dir=tools/goplaces";
      config = {
        env = {
          GOOGLE_PLACES_API_KEY = "/run/agenix/openclawEnv";
        };
      };
    }
  ];
  hooPlugins = [ ];
  vanillaPlugins = [ ];
in
{
  bundledPlugins = { };

  inherit commonPlugins hooPlugins vanillaPlugins;

  pluginsByInstance = {
    hoo = commonPlugins ++ hooPlugins;
    vanilla = commonPlugins ++ vanillaPlugins;
  };
}
