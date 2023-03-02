{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.custom.roles.multimedia.converters;

in

{
  options = {
    custom.roles.multimedia.converters = {
      enable = mkEnableOption "Enable converting tools";
    };
  };

  config = mkIf cfg.enable {
    custom.programs.abcde.enable = true;

    home = {
      packages = with pkgs; [
        handbrake
        picard
      ];

      file."bin/mp3conv" = {
        executable = true;
        source = ./scripts/mp3conv;
      };
    };
  };
}
