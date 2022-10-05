{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.custom.roles.dev.intellij;

in

{
  options = {
    custom.roles.dev.intellij = {
      enable = mkEnableOption "IntelliJ";
    };
  };

  config = mkIf cfg.enable {
    home = {
      packages = with pkgs; [
        openjfx11
        jetbrains.idea-ultimate
        (nerdfonts.override { fonts = [ "FiraCode" ]; })
      ];

      sessionVariables = {
        # IntelliJ IDEA Code with me
        INTELLIJCLIENT_JDK = "${pkgs.jdk11}/lib/openjdk";
      };
    };
  };
}
