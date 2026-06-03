{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let

  cfg = config.custom.users.christian.vim;

in

{
  options = {
    custom.users.christian.vim = {
      enable = mkEnableOption "VIM config";
    };
  };

  config = mkIf cfg.enable {
    custom.users.christian.vim = {
      coc.enable = true;
    };

    home = {
      sessionVariables = {
        EDITOR = "vim";
      };
    };

    programs.neovim = {
      enable = true;
      withPython3 = false;
      withRuby = false;

      initLua = ''
        vim.opt.clipboard = 'unnamedplus'
        vim.opt.cursorline = true
        vim.opt.relativenumber = true
        vim.opt.number = true
        vim.opt.foldmethod = 'marker'
        vim.opt.splitright = true
        vim.opt.splitbelow = true
        vim.opt.linebreak = true

        --------------
        -- SURROUND --
        --------------

        require('nvim-surround').setup({
          move_cursor = 'sticky'
        })

        ----------------
        -- TREESITTER --
        ----------------

        -- nvim-treesitter's main-branch rewrite dropped the module system
        -- (`nvim-treesitter.configs`). Highlighting is now Neovim's built-in
        -- `vim.treesitter.start()` and indentation comes from the plugin's
        -- `indentexpr()`. Grammars/queries ship via Nix (withAllGrammars).
        vim.api.nvim_create_autocmd('FileType', {
          callback = function()
            pcall(vim.treesitter.start)
            vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
          end,
        })
      '';

      plugins = with pkgs.vimPlugins; [
        vim-nix

        # Markdown
        tabular
        vim-markdown

        # Misc
        nvim-surround
        nvim-treesitter.withAllGrammars
      ];

      viAlias = true;
      vimAlias = true;
      vimdiffAlias = true;
    };
  };
}
