let
  commonPlugins = [ ];
  hooPlugins = [ ];
  vanillaPlugins = [ ];
in
{
  bundledPlugins = {
    summarize = {
      enable = true;
      config.env.OPENAI_API_KEY = "/run/agenix/openclawEnv";
    };
    goplaces = {
      enable = true;
      config.env.GOOGLE_PLACES_API_KEY = "/run/agenix/openclawEnv";
    };
    sag = {
      enable = true;
      config.env.ELEVENLABS_API_KEY = "/run/agenix/openclawEnv";
    };
  };

  inherit commonPlugins hooPlugins vanillaPlugins;

  pluginsByInstance = {
    hoo = commonPlugins ++ hooPlugins;
    vanilla = commonPlugins ++ vanillaPlugins;
  };
}
