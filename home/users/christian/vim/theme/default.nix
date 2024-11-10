{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let

  cfg = config.custom.users.christian.vim.theme;

in

{
  options = {
    custom.users.christian.vim.theme = {
      enable = mkEnableOption "VIM theme config";
    };
  };

  config = mkIf cfg.enable {
    programs.neovim = {
      extraLuaConfig = ''
        -------------------
        -- ONEDARK THEME --
        -------------------

        require("onedarkpro").setup({
          styles = {
            types = "NONE",
            methods = "NONE",
            numbers = "NONE",
            strings = "NONE",
            comments = "italic",
            keywords = "bold,italic",
            constants = "NONE",
            functions = "italic",
            operators = "NONE",
            variables = "NONE",
            parameters = "NONE",
            conditionals = "italic",
            virtual_text = "NONE",
          },
          options = {
            cursorline = true,
            transparency = true
          }
        })

        vim.cmd("colorscheme onedark")
      '';

      plugins = with pkgs.vimPlugins; [ onedarkpro-nvim ];
    };
  };
}
