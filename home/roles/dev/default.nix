{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let

  cfg = config.custom.roles.dev;

in

{
  options = {
    custom.roles.dev = {
      enable = mkEnableOption "Development configs";
    };
  };

  config = mkIf cfg.enable {
    custom.roles.dev = {
      android.enable = true;
      claudecode.enable = true;
      embedmongo.enable = false;
      intellij.enable = true;
      java.enable = true;
      js.enable = true;
      opencode.enable = true;
      plantuml.enable = true;
      scala.enable = true;
      zed.enable = true;
    };

    home.packages = with pkgs; [
      ascii
      dbeaver-bin
      libxml2
      wrk
    ];
  };
}
