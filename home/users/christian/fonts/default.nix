{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let

  cfg = config.custom.users.christian.fonts;

in

{
  options = {
    custom.users.christian.fonts = {
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
