{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;

  cfg = config.custom.base.system.boot;
in
{
  options.custom.base.system.boot = {
    enable = mkEnableOption "Enable boot configuration" // {
      default = true;
    };
    secureBoot = mkEnableOption "Enable secure boot";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = lib.optionals cfg.secureBoot [ pkgs.sbctl ];

    boot = {
      lanzaboote = mkIf cfg.secureBoot {
        enable = true;
        pkiBundle = "/var/lib/sbctl";
      };

      loader = {
        efi.canTouchEfiVariables = true;

        systemd-boot = {
          enable = !cfg.secureBoot;
          configurationLimit = 20;
          editor = false;
        };
      };
    };
  };
}
