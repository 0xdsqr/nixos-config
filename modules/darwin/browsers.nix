{
  flake.darwinModules.browsers = _: {
    homebrew.casks = [
      "chromium"
      "helium-browser"
      "zen-browser"
    ];
  };
}
