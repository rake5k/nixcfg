{ config, lib, ... }:

let

  inherit (lib) mkEnableOption mkIf;

  cfg = config.custom.roles.nas.syncthing;

in

{
  options = {
    custom.roles.nas.syncthing = {
      enable = mkEnableOption "Syncthing config";
    };
  };

  config = mkIf cfg.enable {
    custom.base.system.btrfs.impermanence.extraDirectories = [ config.services.syncthing.dataDir ];

    services = {
      syncthing = {
        enable = true;
        dataDir = "/var/lib/syncthing";
        openDefaultPorts = true;

        settings = {
          devices = {
            altair = {
              addresses = [ "tcp://altair.lan.harke.ch:22000" ];
              id = "5X2IF5F-VEV27CQ-B3SIGJH-AMCKBCJ-3D7N7MC-I4TNSCG-AKOGL4P-ABM2VQR";
            };
            malmok = {
              addresses = [ "tcp://10.0.10.2:22000" ];
              id = "JJXAPCO-MOJLFVL-3YHBIXK-YUGQWXF-SWEGZTH-7DW2XAS-GDSQ3KC-RUQVBAB";
            };
            pc-win-chr = {
              addresses = [ "tcp://altair.lan.harke.ch:22000" ];
              id = "4F3YSKI-OS2DO77-KKX2F45-5L627YH-6IL7KNK-72OBJ6U-7K4KMAV-ZRHZGQV";
            };
            pixel-7a = {
              addresses = [ "tcp://10.0.10.7:22000" ];
              id = "XKSHGGN-JSMIPZ3-MUDZHEM-LH2I6KZ-B3WTV3X-R2ZLCBI-QHPJTFR-ELYCIQN";
            };
            retropie = {
              addresses = [ ];
              id = "WJM37IG-DIXQ5NL-6BBLEJP-MT67BKR-C7WMLT3-QD2HZYZ-SQGR25I-JLA4DAI";
            };
            sirius-a = {
              addresses = [ ];
              id = "WTYJYH5-XTTBBTX-TJ2KUSE-7R7Q77T-4HCEO4R-CJMWKCD-ZGYV2AI-TG3NHQH";
            };
          };

          folders = {
            FreeTube = {
              enable = true;
              devices = [
                config.services.syncthing.settings.devices.altair.name
                config.services.syncthing.settings.devices.pc-win-chr.name
                config.services.syncthing.settings.devices.malmok.name
                config.services.syncthing.settings.devices.pixel-7a.name
                config.services.syncthing.settings.devices.sirius-a.name
              ];
              id = "jongs-ayrxt";
              path = "/data/syncthing/FreeTube";
            };
            RetroDeck = {
              enable = true;
              devices = [
                config.services.syncthing.settings.devices.sirius-a.name
              ];
              id = "gbpxu-zscyz";
              path = "/data/syncthing/RetroDeck";
            };
            RetroPie = {
              enable = true;
              devices = [
                config.services.syncthing.settings.devices.retropie.name
              ];
              id = "l75h5-auqfx";
              path = "/data/syncthing/RetroPie";
            };
          };

          # Prevent "Host check error"
          # https://docs.syncthing.net/users/faq.html#why-do-i-get-host-check-error-in-the-gui-api
          gui.insecureSkipHostcheck = true;

          options = {
            urAccepted = -1;
          };
        };
      };

      traefik = {
        dynamicConfigOptions = {
          http = {
            services = {
              syncthing.loadBalancer.servers = [ { url = "http://${config.services.syncthing.guiAddress}"; } ];
            };

            routers = {
              syncthing = {
                entryPoints = [ "websecure" ];
                rule = "Host(`syncthing.local.harke.ch`)";
                service = "syncthing";
                tls.certResolver = "letsencrypt";
              };
            };
          };
        };
      };
    };
  };
}
