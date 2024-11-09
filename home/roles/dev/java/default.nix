{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let

  cfg = config.custom.roles.dev.java;

  java = pkgs.jdk;
  visualvm = pkgs.visualvm.override { jdk = pkgs.jdk8; };

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
        visualvm
      ];

      sessionVariables = {
        JAVA_HOME = "${java}/lib/openjdk";
        JDK_HOME = "${java}/lib/openjdk";
      };

      file.".gradle" = {
        recursive = true;
        source = ./gradle;
      };
    };
  };
}
