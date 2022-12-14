{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.custom.roles.dev.intellij;
  ideaPackage =
    if cfg.ultimate then
      pkgs.jetbrains.idea-ultimate else
      pkgs.jetbrains.idea-community;

in

{
  options = {
    custom.roles.dev.intellij = {
      enable = mkEnableOption "IntelliJ";

      ultimate = mkOption {
        type = types.bool;
        default = false;
        description = "Whether to Install the Ultimate Edition, Community Edition otherwise.";
      };
    };
  };

  config = mkIf cfg.enable {
    home = {
      packages = with pkgs; [
        ideaPackage
        openjfx11
        (nerdfonts.override { fonts = [ "FiraCode" ]; })
      ];

      sessionVariables = {
        # IntelliJ IDEA Code with me
        INTELLIJCLIENT_JDK = "${pkgs.jdk11}/lib/openjdk";
      };
    };
  };
}
