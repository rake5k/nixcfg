{ config, lib, pkgs, ... }:

with lib;

let

  inherit (config.lib.custom) genAttrs';

  cfg = config.custom.roles.mobile.bin;

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
    custom.roles.mobile.bin = {
      enable = mkEnableOption "Mobile user bin scripts";
    };
  };

  config = mkIf cfg.enable {
    xdg.configFile = genAttrs'
      [
        "termux-file-editor"
      ]
      mkUserBinScript;
  };
}
