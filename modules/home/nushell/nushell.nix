{
  flake.homeModules.nushell =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (lib.modules) mkIf;
      inherit (lib.strings) optionalString readFile;
      package =
        if pkgs.stdenv.isDarwin then
          pkgs.nushell.overrideAttrs (_: {
            doCheck = false;
          })
        else
          pkgs.nushell;
    in
    {
      home.file.".zshrc" = mkIf pkgs.stdenv.isDarwin {
        text = ''
          # Ghostty launches zsh on Darwin; immediately hand off to Nushell
          # with the Home Manager-managed config so prompt/theme/integrations load.
          SHELL=${package}/bin/nu exec ${package}/bin/nu --config '${config.xdg.configHome}/nushell/config.nu'
        '';
      };

      programs.nushell = {
        enable = true;
        inherit package;
        settings = {
          show_banner = false;
          edit_mode = "vi";
          history = {
            file_format = "sqlite";
            max_size = 100000;
            sync_on_enter = true;
          };
          completions = {
            algorithm = "substring";
            case_sensitive = false;
            quick = true;
            partial = true;
            use_ls_colors = true;
          };
        };
        shellAliases = {
          v = "nvim";
          vim = "nvim";
          lg = "lazygit";
          ll = "ls -la";
          la = "ls -a";
          sl = "ls";
          tree = "eza --tree --git-ignore --group-directories-first";
        };
        extraConfig =
          readFile ./nushell.config.nu
          + optionalString pkgs.stdenv.isDarwin ''
            # agenix only auto-discovers ~/.ssh/id_ed25519 and ~/.ssh/id_rsa,
            # so wrap it to use the homelab key by default on the Mac.
            def --wrapped agenix [...args] {
              ^agenix -i ~/.ssh/dsqr_homelab_ed25519 ...$args
            }
          '';
      };
    };
}
