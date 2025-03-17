{
  config,
  lib,
  pkgs,
  ...
}:

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
        move-to-monitor-up = [ "<Shift><Super>Up" ];
        move-to-workspace-1 = [ "<Super><Shift>1" ];
        move-to-workspace-2 = [ "<Super><Shift>2" ];
        move-to-workspace-3 = [ "<Super><Shift>3" ];
        move-to-workspace-4 = [ "<Super><Shift>4" ];
        move-to-workspace-5 = [ "<Super><Shift>5" ];
        move-to-workspace-6 = [ "<Super><Shift>6" ];
        move-to-workspace-7 = [ "<Super><Shift>7" ];
        move-to-workspace-8 = [ "<Super><Shift>8" ];
        move-to-workspace-9 = [ "<Super><Shift>9" ];
        move-to-workspace-10 = [ "<Super><Shift>0" ];
        move-to-workspace-left = [ "<Shift><Super>h" ];
        move-to-workspace-right = [ "<Shift><Super>l" ];
        switch-to-workspace-1 = [ "<Super>1" ];
        switch-to-workspace-2 = [ "<Super>2" ];
        switch-to-workspace-3 = [ "<Super>3" ];
        switch-to-workspace-4 = [ "<Super>4" ];
        switch-to-workspace-5 = [ "<Super>5" ];
        switch-to-workspace-6 = [ "<Super>6" ];
        switch-to-workspace-7 = [ "<Super>7" ];
        switch-to-workspace-8 = [ "<Super>8" ];
        switch-to-workspace-9 = [ "<Super>9" ];
        switch-to-workspace-10 = [ "<Shift>0" ];
        switch-to-workspace-left = [ "<Super>h" ];
        switch-to-workspace-right = [ "<Super>l" ];
        toggle-fullscreen = [ "<Super>f" ];
      };

      "org/gnome/desktop/wm/preferences" = {
        focus-mode = "sloppy";
        focus-new-windows = "smart";
        num-workspaces = 9;
      };

      "org/gnome/mutter" = {
        dynamic-workspaces = false;
        edge-tiling = false;
        workspaces-only-on-primary = true;
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

      "org/gnome/settings-daemon/plugins/power" = {
        idle-brightness = 100;
      };

      "org/gnome/shell" = {
        disabled-extensions = [
          "ding@rastersoft.com"
          "ubuntu-dock@ubuntu.com"
        ];
        enabled-extensions = [
          "auto-move-windows@gnome-shell-extensions.gcampax.github.com"
          "just-perfection-desktop@just-perfection"
          "space-bar@luchrioh"
          "system-monitor@gnome-shell-extensions.gcampax.github.com"
        ];
      };

      "org/gnome/shell/extensions/auto-move-windows" = {
        application-list = [
          "kitty.desktop:1"
          "org.gnome.Evolution.desktop:2"
          "chromium-browser.desktop:3"
          "firefox.desktop:3"
          "firefox_firefox.desktop:3"
          "element-desktop.desktop:4"
          "chrome-cifhbcnohmdccbgoicgdjpfamggdegmo-Default.desktop:4"
          "slack.desktop:4"
          "freetube.desktop:5"
          "logseq.desktop:5"
        ];
      };

      "org/gnome/shell/extensions/just-perfection" = {
        animation = 2;
        double-super-to-appgrid = false;
        #overlay-key = false;
        startup-status = 0;
        window-maximized-on-create = true;
        workspace-wrap-around = true;
      };

      "org/gnome/shell/extensions/space-bar/behavior" = {
        toggle-overview = false;
      };

      "org/gnome/shell/extensions/space-bar/shortcuts" = {
        enable-move-to-workspace-shortcuts = true;
      };
    };

    home.packages = with pkgs.gnomeExtensions; [
      #auto-move-windows # incompatible with Ubuntu Gnome 46
      just-perfection
      space-bar
      #system-monitor # incompatible with Ubuntu Gnome 46
    ];
  };
}
