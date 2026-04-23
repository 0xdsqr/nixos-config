let
  commonPlugins = [ ];
  hooPlugins = [ ];
  vanillaPlugins = [ ];
in
{
  # Temporary isolation mode: disable bundled skills while we stabilize core
  # chat and image-generation behavior.
  bundledPlugins = { };

  inherit commonPlugins hooPlugins vanillaPlugins;

  pluginsByInstance = {
    hoo = commonPlugins ++ hooPlugins;
    vanilla = commonPlugins ++ vanillaPlugins;
  };
}
