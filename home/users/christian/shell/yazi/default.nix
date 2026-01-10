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
    home.packages = with pkgs; [
      exiftool
    ];

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

          -- Show username and hostname in header
          Status:children_add(function()
            local h = cx.active.current.hovered
            if not h or ya.target_family() ~= "unix" then
              return ""
            end

            return ui.Line {
              ui.Span(ya.user_name(h.cha.uid) or tostring(h.cha.uid)):fg("magenta"),
              ":",
              ui.Span(ya.group_name(h.cha.gid) or tostring(h.cha.gid)):fg("magenta"),
              " ",
            }
          end, 500, Status.RIGHT)

          -- Show username and hostname in header
          Header:children_add(function()
             if ya.target_family() ~= "unix" then
               return ""
             end
             return ui.Span(ya.user_name() .. "@" .. ya.host_name() .. ":"):fg("blue")
          end, 500, Header.LEFT)
        '';

      keymap = {
        input.prepend_keymap = [
          {
            desc = "Cancel input";
            on = [ "<Esc>" ];
            run = "close";
          }
        ];
        mgr.prepend_keymap = [
          {
            on = [
              "g"
              "M"
            ];
            run = "cd /mnt";
          }
        ];
      };

      settings = {
        mgr = {
          linemode = "size";
        };

        opener = {
          firefox = [
            {
              desc = "Open in Firefox";
              run = "firefox \"$@\"";
              orphan = true;
            }
          ];
        };

        open = {
          prepend_rules = [
            {
              mime = "application/pdf";
              use = [
                "open"
                "firefox"
              ];
            }
          ];
        };
      };
    };
  };
}
