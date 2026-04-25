{ pkgs }:
let
  treesitterWithGrammars = pkgs.vimPlugins.nvim-treesitter.withPlugins (p: [
    p.bash
    p.c
    p.css
    p.dockerfile
    p.go
    p.gomod
    p.gosum
    p.html
    p.java
    p.javascript
    p.json
    p.json5
    p.kotlin
    p.lua
    p.markdown
    p.markdown_inline
    p.nix
    p.python
    p.rust
    p.svelte
    p.toml
    p.tsx
    p.typescript
    p.vim
    p.vimdoc
    p.yaml
  ]);
in
[
  {
    plugin = treesitterWithGrammars;
    type = "lua";
    config = ''
      require('nvim-treesitter').setup({
        auto_install = false,
        highlight = {
          enable = true,
          additional_vim_regex_highlighting = false,
        },
        indent = {
          enable = true,
        },
      })
    '';
  }
]
