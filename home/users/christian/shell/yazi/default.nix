{
  config,
  lib,
  pkgs,
  ...
}:

let

  cfg = config.custom.users.christian.shell.yazi;

  inherit (lib) mkEnableOption mkIf;

in

{
  options = {
    custom.users.christian.shell.yazi = {
      enable = mkEnableOption "Yazi configuration";
    };
  };

  config = mkIf cfg.enable {
    programs.yazi = {
      enable = true;

      plugins = with pkgs.yaziPlugins; {
        inherit full-border;
      };

      initLua = # lua
        ''
          require("full-border"):setup {
            type = ui.Border.ROUNDED,
          }
        '';

      keymap = {
        mgr = {
          prepend_keymap = [
            {
              run = "cd /mnt";
              on = [
                "g"
                "M"
              ];
            }
          ];
        };
      };

      settings = {
        mgr = {
          linemode = "size";
        };
      };
    };
  };
}
