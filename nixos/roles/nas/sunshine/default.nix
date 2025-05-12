{
  config,
  lib,
  pkgs,
  ...
}:

let

  cfg = config.custom.roles.nas.sunshine;

  inherit (lib) mkEnableOption mkIf;

in

{
  options = {
    custom.roles.nas.sunshine = {
      enable = mkEnableOption "Sunshine config";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      # Launchers
      prismlauncher

      # Games
      pinball
      space-cadet-pinball
      superTux
      superTuxKart
    ];

    services.sunshine = {
      enable = true;
      capSysAdmin = true;
      openFirewall = true;
    };
  };
}
