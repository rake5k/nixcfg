{ config, lib, ... }:

with lib;

let

  desktopCfg = config.custom.roles.desktop;
  cfg = desktopCfg.gnome;

in

{
  options = {
    custom.roles.desktop.gnome = {
      enable = mkEnableOption "Gnome config";
    };
  };

  config = mkIf cfg.enable {
    dconf.settings = with lib.hm.gvariant; {
      "org/gnome/desktop/applications/terminal" = {
        exec = desktopCfg.terminal.spawnCmd;
        exec-arg = "";
      };

      "org/gnome/desktop/input-sources" = {
        show-all-sources = true;
        sources = [ (mkTuple [ "xkb" "de+neo_qwertz" ]) (mkTuple [ "xkb" "de+bone" ]) ];
      };
    };
  };
}
