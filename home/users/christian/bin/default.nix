{ config, lib, pkgs, ... }:

with lib;

let

  inherit (config.lib.custom) genAttrs';

  cfg = config.custom.users.christian.bin;

  mkUserBinScript = name:
    {
      name = "bin/${name}";
      value = {
        source = ./scripts + "/${name}";
        target = config.home.homeDirectory + "/bin/${name}";
        executable = true;
      };
    };

in

{
  options = {
    custom.users.christian.bin = {
      enable = mkEnableOption "User bin scripts";
    };
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      # Bluetooth
      bluez

      _1password
      pulseaudio
    ];

    xdg.configFile = genAttrs'
      [
        # Bluetooth headset
        "lib/btctl"
        "wh1000xm2-connect"
        "wh1000xm2-disconnect"

        # Password CLI
        "pass"
      ]
      mkUserBinScript;
  };
}
