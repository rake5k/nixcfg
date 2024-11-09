{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let

  cfg = config.custom.roles.gaming.simracing;

  fanatecff = pkgs.linuxPackages.callPackage ../../../../pkgs/hid-fanatecff/default.nix { };

in

{
  options = {
    custom.roles.gaming.simracing = {
      enable = mkEnableOption "Simracing";
    };
  };

  config = mkIf cfg.enable {
    boot = {
      extraModulePackages = [ fanatecff ];
      kernelModules = [ "hid-fanatec" ];
    };

    services.udev.packages = [ fanatecff ];
  };
}
