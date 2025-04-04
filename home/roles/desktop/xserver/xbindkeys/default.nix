{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let

  desktopCfg = config.custom.roles.desktop;
  cfg = desktopCfg.xserver.xbindkeys;
  terminalCfg = desktopCfg.terminal;

  defaultKeymap = {
    XF86AudioLowerVolume = "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-";
    XF86AudioMicMute = "wpctl set-source-mute @DEFAULT_SOURCE@ toggle";
    XF86AudioMute = "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
    XF86AudioNext = "playerctl next";
    XF86AudioPause = "playerctl pause";
    XF86AudioPlay = "playerctl play-pause";
    XF86AudioPrev = "playerctl previous";
    XF86AudioRaiseVolume = "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+";
    XF86AudioStop = "playerctl stop";
    XF86Bluetooth = "${getExe pkgs.bash} -c \"if rfkill list bluetooth|grep -q 'yes$';then rfkill unblock bluetooth;else rfkill block bluetooth;fi\"";
    XF86Calculator = "${terminalCfg.spawnCmd} ${terminalCfg.commandArgPrefix}${getExe pkgs.eva}";
    XF86Eject = "eject";
    XF86Explorer = "${terminalCfg.spawnCmd} ${terminalCfg.commandArgPrefix}${getExe pkgs.yazi}";
    XF86HomePage = "xdg-open";
    XF86MonBrightnessDown = "brightnessctl set 10%-";
    XF86MonBrightnessUp = "brightnessctl set 10%+";
  };

  mkRcEntry =
    keymap:
    concatStringsSep "\n" (
      mapAttrsToList (code: command: ''
        "${command}"
          ${code}
      '') keymap
    );

in

{
  options = {
    custom.roles.desktop.xserver.xbindkeys = {
      enable = mkEnableOption "Xbindkeys";

      keymap = mkOption {
        type = with types; attrsOf str;
        description = "Key mapping";
        default = defaultKeymap;
      };
    };
  };

  config = mkIf cfg.enable {
    custom.roles.desktop.terminal.enable = true;

    home.packages = with pkgs; [
      terminalCfg.package

      brightnessctl
      playerctl
      xbindkeys
    ];

    xdg.configFile."xbindkeysrc" = {
      text = mkRcEntry (defaultKeymap // cfg.keymap);
      target = config.home.homeDirectory + "/.xbindkeysrc";
    };

    xsession.initExtra = ''
      xbindkeys
    '';
  };
}
