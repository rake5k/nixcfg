{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.custom.roles.desktop.wayland.niri;

  inherit (lib)
    getExe
    mkEnableOption
    mkIf
    mkOption
    types
    ;

in

{
  options = {
    custom.roles.desktop.wayland.niri = {
      enable = mkEnableOption "Niri window manager";

      isMobile = mkEnableOption "Enable laptop features";

      volumeCtl = {
        spawnCmd = mkOption {
          type = types.str;
          default = "${getExe pkgs.pavucontrol}";
          description = "Command to spawn the volume control utility";
        };
      };
    };
  };

  config = mkIf cfg.enable {
    custom = {
      roles = {
        desktop = {
          notification = {
            enable = true;
            offset = "15x15";
          };
          wayland.waybar = {
            inherit (cfg) isMobile;
            enable = true;
            volumeCtl = {
              inherit (cfg.volumeCtl) spawnCmd;
            };
          };
        };
      };
    };

    programs = {
      niri = {
        enable = true;
        package = pkgs.niri;
      };

      # supporting tools
      fuzzel = {
        enable = true;
        settings = {
          main = {
            terminal = "kitty";
            layer = "overlay";
          };
        };
      };

      swaylock = {
        enable = true;
        settings = {
          show-failed-attempts = true;
          show-keyboard-layout = true;
        };
      };
    };
  };
}
