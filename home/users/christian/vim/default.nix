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
      theme.enable = true;
    };

    home = {
      sessionVariables = {
        EDITOR = "vim";
      };
    };

    programs.neovim = {
      enable = true;

      extraConfig = ''
        set clipboard=unnamedplus
        set number relativenumber
      '';

      extraLuaConfig = ''
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
