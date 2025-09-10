{
  config,
  lib,
  pkgs,
  ...
}:

let

  cfg = config.custom.roles.desktop.xserver.launcher;

  dmenuPatched = pkgs.dmenu.override {
    patches = builtins.map builtins.fetchurl [
      {
        url = "https://tools.suckless.org/dmenu/patches/line-height/dmenu-lineheight-5.2.diff";
        sha256 = "0jabb2ycfn3xw0k2d2rv7nyas5cwjr6zvwaffdn9jawh62c50qy5";
      }
      {
        url = "https://tools.suckless.org/dmenu/patches/center/dmenu-center-5.2.diff";
        sha256 = "1jck88ypx83b73i0ys7f6mqikswgd2ab5q0dfvs327gsz11jqyws";
      }
    ];
  };

  inherit (lib)
    mkEnableOption
    mkIf
    mkOption
    types
    ;

in

{
  options = {
    custom.roles.desktop.xserver.launcher = {
      enable = mkEnableOption "Launcher";

      package = mkOption {
        type = types.package;
        default = dmenuPatched;
        description = "Launcher package to use";
      };

      launcherCmd = mkOption {
        type = types.str;
        default = "${dmenuPatched}/bin/dmenu_run -c -i -fn \"Monofur Nerd Font:style=Bold:size=20:antialias=true\" -l 8 -nf \"#C5C8C6\" -sb \"#373B41\" -sf \"#C5C8C6\" -p \"run:\"";
        description = "Command to spawn launcher";
      };
    };
  };

  config = mkIf cfg.enable {
    home.packages = [
      cfg.package
    ];
  };
}
