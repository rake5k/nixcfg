{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let

  cfg = config.custom.roles.dev.android;

in

{
  options = {
    custom.roles.dev.android = {
      enable = mkEnableOption "Android tooling";
    };
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      android-tools
      signify
    ];
  };
}
