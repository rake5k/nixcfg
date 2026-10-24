{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let

  cfg = config.custom.roles.ops;

in

{
  options = {
    custom.roles.ops = {
      enable = mkEnableOption "Operations";
    };
  };

  config = mkIf cfg.enable (mkMerge [
    {
      home.packages = [ pkgs.lnav ];

      # yazi opens text/* with $EDITOR instead of xdg-open, and libmagic types .log as text/plain
      programs.yazi.settings = {
        opener.lnav = [
          {
            run = "lnav %s";
            desc = "lnav";
            for = "unix";
            block = true;
          }
        ];
        open.prepend_rules = [
          {
            url = "*.log";
            use = [
              "lnav"
              "edit"
              "reveal"
            ];
          }
        ];
      };
    }

    # lnav ships no desktop entry; overrides the nvim association from the vim module
    (mkIf config.custom.roles.desktop.enable {
      xdg = {
        desktopEntries.lnav = {
          name = "lnav";
          genericName = "Log File Navigator";
          exec = "lnav %F";
          terminal = true;
          categories = [
            "System"
            "Monitor"
          ];
          mimeType = [ "text/x-log" ];
        };

        mimeApps.defaultApplications."text/x-log" = mkForce "lnav.desktop";
      };
    })
  ]);
}
