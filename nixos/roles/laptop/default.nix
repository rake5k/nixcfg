{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.custom.roles.laptop;

in

{
  options = {
    custom.roles.laptop = {
      enable = mkEnableOption "Laptop computer config";
    };
  };

  config = mkIf cfg.enable {
    custom.programs = {
      direnv.enable = true;
    };

    services = {
      logind = {
        lidSwitch = "suspend-then-hibernate";
        lidSwitchDocked = "ignore";
        lidSwitchExternalPower = "lock";
      };

      upower.enable = true;

      xserver = {
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
    };

    networking.networkmanager.dispatcherScripts = [{
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
    }];
  };
}
