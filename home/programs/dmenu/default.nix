{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.custom.programs.dmenu;

  dmenuPatched = pkgs.dmenu.override {
    patches = builtins.map builtins.fetchurl [
      {
        url = "https://tools.suckless.org/dmenu/patches/line-height/dmenu-lineheight-5.2.diff";
        sha256 = "0jabb2ycfn3xw0k2d2rv7nyas5cwjr6zvwaffdn9jawh62c50qy5";
      }
    ];
  };

in

{
  options = {
    custom.programs.dmenu = {
      enable = mkEnableOption "Dmenu launcher";

      font = {
        package = mkOption {
          type = types.package;
          default = pkgs.nerdfonts;
          description = "Font derivation";
        };
      };
    };
  };

  config = mkIf cfg.enable {
    home.packages = [
      dmenuPatched
      cfg.font.package
    ];
  };
}
