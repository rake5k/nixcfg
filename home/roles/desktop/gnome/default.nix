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
        sources = [
          (mkTuple [
            "xkb"
            "de+neo_qwertz"
          ])
          (mkTuple [
            "xkb"
            "de+bone"
          ])
        ];
      };

      "org/gnome/desktop/wm/keybindings" = {
        close = [ "<Shift><Super>c" ];
      };

      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0" = {
        binding = "<Shift><Super>Return";
        command = desktopCfg.terminal.spawnCmd;
        name = "terminal";
      };

      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1" = {
        binding = "<Control><Super>w";
        command = desktopCfg.wiki.spawnCmd;
        name = "wiki";
      };

      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom2" = {
        binding = "<Control><Super>p";
        command = desktopCfg.passwordManager.spawnCmd;
        name = "password-manager";
      };

      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom3" = {
        binding = "<Control><Super>k";
        command = "gnome-calendar";
        name = "calendar";
      };

      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom4" = {
        binding = "<Control><Super>t";
        command = "gnome-system-monitor";
        name = "task-manager";
      };
    };
  };
}
