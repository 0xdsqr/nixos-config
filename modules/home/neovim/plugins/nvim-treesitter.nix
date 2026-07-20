{ lib, pkgs }:
let
  inherit (lib.lists) singleton;

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
singleton {
  plugin = treesitterWithGrammars;
  type = "lua";
  config = /* lua */ ''
    require('nvim-treesitter').setup({})

    vim.api.nvim_create_autocmd('FileType', {
      group = vim.api.nvim_create_augroup('UserTreesitter', { clear = true }),
      pattern = {
        'bash', 'c', 'css', 'dockerfile', 'go', 'gomod', 'gosum', 'html',
        'java', 'javascript', 'json', 'json5', 'kotlin', 'lua', 'markdown',
        'nix', 'python', 'rust', 'svelte', 'toml', 'typescript', 'typescriptreact',
        'vim', 'vimdoc', 'yaml',
      },
      callback = function(event)
        if pcall(vim.treesitter.start, event.buf) then
          vim.bo[event.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
        end
      end,
    })
  '';
}
