{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let

  cfg = config.custom.roles.desktop.mobile;

in

{
  options = {
    custom.roles.desktop.mobile = {
      enable = mkEnableOption "Mobile computer config";
    };
  };

  config = mkIf cfg.enable {
    services = {
      logind = {
        lidSwitch = "suspend-then-hibernate";
        lidSwitchDocked = "ignore";
        lidSwitchExternalPower = "lock";
      };

      thermald.enable = true;
      tlp.enable = true;
      upower.enable = true;

      # Touchpad settings
      libinput = {
        enable = true;
        touchpad = {
          naturalScrolling = true;
          disableWhileTyping = true;
          sendEventsMode = "disabled-on-external-mouse";
        };
      };
    };

    networking.networkmanager.dispatcherScripts = [
      {
        source = pkgs.writeText "99-disable-wireless-when-wired" ''
          myname=''${0##*/}
          log() { logger -p user.info -t "''${myname}[$$]" "$*"; }
          IFACE=$1
          ACTION=$2

          case ''${IFACE} in
          eth*|usb*|en*)
              case ''${ACTION} in
                  up)
                      log "disabling wifi radio"
                      rfkill block wifi
                      ;;
                  down)
                      log "enabling wifi radio"
                      rfkill unblock wifi
                      ;;
              esac
              ;;
          esac
        '';
        type = "basic";
      }
    ];
  };
}
