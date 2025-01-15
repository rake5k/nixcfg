{ config, lib, ... }:

let

  inherit (lib)
    mkEnableOption
    mkIf
    mkOption
    types
    ;

  cfg = config.custom.base.system.network;

in

{
  options = {
    custom.base.system.network = {
      enable = mkEnableOption "Network config" // {
        default = true;
      };

      wol = {
        enable = mkEnableOption "Wake on LAN";

        interface = mkOption {
          type = types.str;
          description = ''
            Interface to listen for magic packets.
          '';
        };
      };
    };
  };

  config = mkIf cfg.enable {
    networking = {
      firewall = {
        enable = true;
        allowPing = true;
      };

      interfaces = mkIf cfg.wol.enable {
        ${cfg.wol.interface} = {
          wakeOnLan = {
            enable = true;
            policy = [ "magic" ];
          };
        };
      };

      networkmanager.enable = true;
      useDHCP = lib.mkDefault true;
    };

    programs.nm-applet.enable = config.custom.roles.desktop.enable;

    # Enable the OpenSSH daemon.
    services.openssh = {
      enable = true;
      settings.PasswordAuthentication = false;
    };
  };
}
