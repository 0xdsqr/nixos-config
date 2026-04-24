{
  flake.homeModules.ghostty =
    {
      pkgs,
      ...
    }: {
      programs.ghostty = {
        enable = true;
        package = if pkgs.stdenv.hostPlatform.isDarwin then pkgs.ghostty-bin else pkgs.ghostty;
        settings = {
          # Window settings
          window-padding-x = 10;
          window-padding-y = 10;
          confirm-close-surface = false;
          resize-overlay = "never";
          unfocused-split-opacity = 0.78;
          unfocused-split-fill = "#111111";
          split-divider-color = "#2a2a2a";
          mouse-scroll-multiplier = 0.95;

          # Font
          font-family = "JetBrains Mono";
          font-size = 18;
          cursor-style = "block";
          cursor-style-blink = false;
          shell-integration-features = "no-cursor,ssh-env";

          # Basic keybinds
          keybind = [
            "ctrl+k=reset"
            "ctrl+shift+h=goto_split:left"
            "ctrl+shift+j=goto_split:bottom"
            "ctrl+shift+k=goto_split:top"
            "ctrl+shift+l=goto_split:right"
            "ctrl+shift+n=new_split:down"
            "ctrl+shift+w=close_surface"
          ];
        };
      };
    };
}
