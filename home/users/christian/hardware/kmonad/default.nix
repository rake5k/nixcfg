{ config, lib, ... }:

with lib;

let

  cfg = config.custom.users.christian.hardware.kmonad;

in

{
  options = {
    custom.users.christian.hardware.kmonad = {
      enable = mkEnableOption "Kmonad service";
    };
  };

  config = mkIf cfg.enable {
    custom.programs.kmonad = {
      enable = true;
      configFiles = {
        WASD_V3 = ./wasd-v3.de-ch.kbd;
        CHERRY_G80 = ./cherry-mx-g80-3000n-tkl-rgb.de-ch.kbd;
      };
    };
  };
}
