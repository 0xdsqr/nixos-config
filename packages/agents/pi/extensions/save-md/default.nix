{
  description = "Safely save the latest completed Pi assistant response to a workspace or private document library";
  enableByDefault = true;
  settings = {
    libraryDirectory = null;
  };
  settingsFile = "save-md.json";
  source = ./.;
}
