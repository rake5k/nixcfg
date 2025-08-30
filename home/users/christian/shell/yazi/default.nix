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
    programs.yazi =
      let
        gruvbox-dark = pkgs.yaziPlugins.mkYaziPlugin {
          pname = "gruvbox-dark.yazi";
          version = "0-unstable-2025-08-18";
          src = pkgs.fetchFromGitHub {
            owner = "bennyyip";
            repo = "gruvbox-dark.yazi";
            rev = "e5e1aefbfb5641b487cb4a11ccbc57346ec8e130";
            hash = "sha256-NeePBNhMVXyIrED4Iu4ZSHwwgsd3CV8oBzYoQOWsD/U=";
          };
          meta = {
            description = "gruvbox-dark flavor";
            homepage = "https://github.com/bennyyip/gruvbox-dark.yazi";
            license = lib.licenses.mit;
            maintainers = with lib.maintainers; [ rake5k ];
          };
        };

        nord = pkgs.yaziPlugins.mkYaziPlugin {
          pname = "nord.yazi";
          version = "0-unstable-2025-06-03";
          src = pkgs.fetchFromGitHub {
            owner = "AdithyanA2005";
            repo = "nord.yazi";
            rev = "3a791e9197a3d3ce7003d46ab6712bfc8fef666b";
            hash = "sha256-ubPIPasm1KHVX95nRvt03I1aLDh1qUtGL8sOHGJeZrU=";
          };
          meta = {
            description = "nord flavor";
            homepage = "https://github.com/AdithyanA2005/nord.yazi";
            license = lib.licenses.mit;
            maintainers = with lib.maintainers; [ rake5k ];
          };
        };
      in
      {
        enable = true;

        plugins = with pkgs.yaziPlugins; {
          inherit full-border;
        };

        flavors = {
          inherit gruvbox-dark nord;
        };

        initLua = ''
          require("full-border"):setup {
            type = ui.Border.ROUNDED,
          }
        '';

        keymap = {
          mgr.prepend_keymap = [
            {
              run = "cd /mnt";
              on = [
                "g"
                "M"
              ];
            }
          ];
        };

        settings = {
          mgr = {
            linemode = "size";
          };
        };

        theme.flavor = {
          dark = "nord";
          light = "nord";
        };
      };
  };
}
