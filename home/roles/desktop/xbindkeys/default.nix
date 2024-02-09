{ config, lib, pkgs, ... }:

with lib;

let

  desktopCfg = config.custom.roles.desktop;
  cfg = desktopCfg.xbindkeys;
  terminalCfg = desktopCfg.terminal;

in

{
  options = {
    custom.roles.desktop.xbindkeys = {
      enable = mkEnableOption "Xbindkeys";
    };
  };

  config = mkIf cfg.enable {
    custom.roles.desktop.terminal.enable = true;

    home.packages = with pkgs; [
      # Audio control
      playerctl

      xbindkeys
    ] + [
      terminalCfg.package
    ];

    xdg.configFile."xbindkeysrc" = {
      text = ''
        "pactl set-sink-volume 0 -5%"
          XF86AudioLowerVolume

        "pactl set-sink-volume 0 +5%"
          XF86AudioRaiseVolume

        "pactl set-sink-mute 0 toggle"
          XF86AudioMute

        "pactl set-source-mute 1 toggle"
          XF86AudioMicMute

        "playerctl play"
          XF86AudioPlay

        "playerctl stop"
          XF86AudioStop

        "playerctl pause"
          XF86AudioPause

        "playerctl next"
          XF86AudioNext

        "playerctl previous"
          XF86AudioPrev

        "bash -c \"if rfkill list bluetooth|grep -q 'yes$';then rfkill unblock bluetooth;else rfkill block bluetooth;fi\""
          XF86Bluetooth

        # FIXME Only working once?
        "${terminalCfg.commandSpawnCmd} eva"
          XF86Calculator

        "${terminalCfg.commandSpawnCmd} ranger"
          XF86Explorer

        "xdg-open"
          XF86HomePage

        # TODO:
        #"gsettings"
        #  XF86Tools
      '';
      target = config.home.homeDirectory + "/.xbindkeysrc";
    };

    xsession.initExtra = ''
      xbindkeys
    '';
  };
}
