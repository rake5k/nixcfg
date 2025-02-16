{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let

  cfg = config.custom.roles.fonts;

in

{
  options = {
    custom.roles.fonts = {
      enable = mkEnableOption "Fonts";
    };
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      google-fonts
      ubuntu-classic
      ubuntu-sans
      ubuntu-sans-mono
    ];
  };
}
