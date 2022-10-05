{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.custom.roles.dev.java;

  java = pkgs.jdk;

in

{
  options = {
    custom.roles.dev.java = {
      enable = mkEnableOption "Java";
    };
  };

  config = mkIf cfg.enable {
    home = {
      packages = [
        java
      ];

      sessionVariables = {
        JAVA_HOME = "${java}/lib/openjdk";
        JDK_HOME = "${java}/lib/openjdk";
      };
    };
  };
}
