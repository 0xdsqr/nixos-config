{
  flake.homeModules.nushell =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (lib)
        getExe
        mkAfter
        mkIf
        mkMerge
        ;
      package =
        if pkgs.stdenv.isDarwin then
          pkgs.nushell.overrideAttrs (_: {
            doCheck = false;
          })
        else
          pkgs.nushell;
      nuExe = getExe config.programs.nushell.package;
    in
    mkMerge [
      {
        programs.nushell = {
          enable = true;
          inherit package;
          settings = {
            show_banner = false;
            edit_mode = "vi";
            history.file_format = "sqlite";
            completions = {
              algorithm = "fuzzy";
              quick = true;
              partial = true;
            };
          };
          shellAliases = {
            v = "nvim";
            vim = "nvim";
            lg = "lazygit";
            ll = "ls -la";
            la = "ls -a";
          };
          extraConfig = ''
            $env.EDITOR = "nvim"
            $env.VISUAL = "nvim"
            $env.config.buffer_editor = "nvim"
          '';
        };
      }

      (mkIf pkgs.stdenv.isDarwin {
        programs.zsh.initContent = mkAfter ''
          if [[ -o interactive ]] && [[ -z "''${__DSQR_NU_HANDOFF:-}" ]]; then
            export __DSQR_NU_HANDOFF=1
            export SHELL="${nuExe}"
            exec "${nuExe}" --config "$HOME/.config/nushell/config.nu"
          fi
        '';
      })
    ];
}
