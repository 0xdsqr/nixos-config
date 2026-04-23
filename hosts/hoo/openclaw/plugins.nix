let
  commonPlugins = [ ];
  hooPlugins = [ ];
  vanillaPlugins = [ ];
in
{
  bundledPlugins = {
    # These plugins inherit provider keys from the gateway service
    # EnvironmentFile. Pointing config.env.* at the shared multi-key env file
    # makes OpenClaw treat the whole file contents as a single secret.
    summarize.enable = true;
    goplaces.enable = true;
    sag.enable = true;
  };

  inherit commonPlugins hooPlugins vanillaPlugins;

  pluginsByInstance = {
    hoo = commonPlugins ++ hooPlugins;
    vanilla = commonPlugins ++ vanillaPlugins;
  };
}
