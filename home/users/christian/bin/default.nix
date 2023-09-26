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
    home = {
      packages = with pkgs; [
        _1password
      ];

      file = genAttrs'
        [
          # Password CLI
          "pass"
        ]
        mkUserBinScript;
    };
  };
}
