{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.custom.roles.dev.scala;

in

{
  options = {
    custom.roles.dev.scala = {
      enable = mkEnableOption "Scala";

      repositories = mkOption {
        type = types.str;
        default = "";
        description = "Lines to be added into repositories config";
      };
    };
  };

  config = mkIf cfg.enable {
    home = {
      packages = with pkgs; [
        ammonite # REPL
        sbt
      ];

      file = {
        ".sbt" = {
          recursive = true;
          source = ./config;
        };
        ".sbt/repositories".text = cfg.repositories;
      };
    };
  };
}
