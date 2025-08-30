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

      extraLuaConfig = ''
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
      '';

      plugins = with pkgs.vimPlugins; [
        vim-nix

        # Markdown
        tabular
        vim-markdown

        # Misc
        nvim-surround
      ];

      viAlias = true;
      vimAlias = true;
      vimdiffAlias = true;
    };
  };
}
