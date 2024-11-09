{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let

  cfg = config.custom.roles.printing;

in

{
  options = {
    custom.roles.printing = {
      enable = mkEnableOption "Printing config";
    };
  };

  config = mkIf cfg.enable {
    services.printing = {
      enable = true;
      drivers = [ pkgs.hplip ];
    };

    hardware = {
      printers.ensurePrinters = [
        {
          name = "pr-hp-chr";
          location = "Home Office";
          description = "HP Officejet Pro 8600 Plus";
          deviceUri = "hp:/net/Officejet_Pro_8600?hostname=pr-hp-chr";
          model = "drv:///hp/hpcups.drv/hp-officejet_pro_8600.ppd";
          ppdOptions = {
            "PageSize" = "A4";
            "Duplex" = "DuplexNoTumble";
            "InputSlot" = "Tray2";
            "ColorModel" = "KGray";
            "MediaType" = "Plain";
            "OutputMode" = "Normal";
            "OptionDuplex" = "True";
          };
        }
      ];

      sane = {
        enable = true;
        extraBackends = [ pkgs.hplip ];
      };
    };
  };
}
