{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.custom.roles.mobile.bin;

in

{
  options = {
    custom.roles.mobile.bin = {
      enable = mkEnableOption "Mobile user bin scripts";
    };
  };

  config = mkIf cfg.enable {
    home.file."bin/termux-file-editor" = {
      source = ./scripts/termux-file-editor;
      executable = true;
    };
  };
}
