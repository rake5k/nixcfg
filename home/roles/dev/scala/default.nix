{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let

  cfg = config.custom.roles.dev.scala;

in

{
  options = {
    custom.roles.dev.scala = {
      enable = mkEnableOption "Scala";
    };
  };

  config = mkIf cfg.enable {
    home = {
      packages = with pkgs; [
        ammonite # REPL
      ];

      file = {
        ".sbt" = {
          recursive = true;
          source = ./config;
        };
      };
    };
  };
}
