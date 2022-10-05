{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.custom.users.christian.hardware.xbindkeys;

in

{
  options = {
    custom.users.christian.hardware.xbindkeys = {
      enable = mkEnableOption "Xbindkeys";
    };
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      alacritty

      # Audio control
      alsa-lib
      playerctl

      xbindkeys
    ];

    xdg.configFile."xbindkeysrc" = {
      text = ''
        #"pactl set-sink-volume 0 -5%" # PulseAudio
        "amixer set Master 5%-" # Alsa
          XF86AudioLowerVolume

        #"pactl set-sink-volume 0 +5%" # PulseAudio
        "amixer set Master 5%+" # Alsa
          XF86AudioRaiseVolume

        #"pactl set-sink-mute 0 toggle" # PulseAudio
        "amixer -q set Master toggle" # Alsa
          XF86AudioMute

        #"pactl set-source-mute 1 toggle" # PulseAudio
        "amixer -q set Capture toggle" # Alsa
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

        # FIXME Only working once?
        "alacritty --command eva"
          XF86Calculator

        "alacritty --command ranger"
          XF86Explorer

        "xdg-open"
          XF86HomePage
      '';
      target = config.home.homeDirectory + "/.xbindkeysrc";
    };

    xsession.initExtra = ''
      xbindkeys
    '';
  };
}
