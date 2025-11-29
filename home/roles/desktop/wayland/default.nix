{
  config,
  lib,
  pkgs,
  ...
}:

let

  desktopCfg = config.custom.roles.desktop;
  cfg = desktopCfg.wayland;

  inherit (lib)
    getExe
    literalExpression
    mkEnableOption
    mkIf
    mkOption
    types
    ;

  screenshotScript = pkgs.writeShellScript "wayland-screenshot" ''
    set -uo pipefail

    notify_success() {
      ${pkgs.libnotify}/bin/notify-send -u low "''${1}" "''${2}"
    }

    notify_failure() {
      ${pkgs.libnotify}/bin/notify-send -u critical "Taking screenshot failed" "''${1}"
    }

    screenshot() {
      OUTDIR="''${HOME}/Pictures/screenshots"
      OUT="''${OUTDIR}/$(${pkgs.coreutils}/bin/date +%F_%H-%M-%S).png"

      ${pkgs.coreutils}/bin/mkdir -p "''${OUTDIR}"

      case $1 in
      full)
        if ${getExe pkgs.grim} "''${OUT}"; then
          notify_success "Fullscreen screenshot saved" "''${OUT}"
        else
          notify_failure "Fullscreen screenshot failed"
        fi
      ;;
      select)
        ${pkgs.coreutils}/bin/sleep 0.5
        GEOMETRY="$(${getExe pkgs.slurp} -d)"
        if [[ -n "''${GEOMETRY}" ]]; then
          if ${getExe pkgs.grim} -g "''${GEOMETRY}" "''${OUT}"; then
            notify_success "Selection screenshot saved" "''${OUT}"
          else
            notify_failure "Selection screenshot failed"
          fi
        else
          notify_failure "Selection screenshot aborted"
        fi
      ;;
      window)
        GEOMETRY="$(${getExe pkgs.slurp} -o -r -c '#ffff00')"
        if [[ -n "''${GEOMETRY}" ]]; then
          if ${getExe pkgs.grim} -g "''${GEOMETRY}" "''${OUT}"; then
            notify_success "Window screenshot saved" "''${OUT}"
          else
            notify_failure "Window screenshot failed"
          fi
        else
          notify_failure "Window screenshot aborted"
        fi
      ;;
      *)
        notify_failure "An invalid argument has been passed: '$1'. Valid values are: 'full', 'select', 'window'"
      esac;
    }

    screenshot "''${1}"
  '';

in

{
  options = {
    custom.roles.desktop.wayland = {
      enable = mkEnableOption "Wayland config";

      autoruns = mkOption {
        type = types.listOf config.lib.custom.autorunType;
        default = desktopCfg.autoruns;
        description = ''
          Applications to be launched in a workspace of choice.
        '';
        example = literalExpression ''
          [
            { command = "firefox"; workspace = 1; }
            { command = "slack"; workspace = 2; }
            { command = "spotify"; workspace= 3; }
          ]
        '';
      };

      wallpapersDir = mkOption {
        type = types.path;
        description = "Path to the wallpaper images";
        default = desktopCfg.wallpapersDir;
      };
    };
  };

  config = mkIf cfg.enable {
    custom.roles.desktop.wayland = {
      kanshi.enable = true;
      river = {
        enable = true;
        inherit (cfg) autoruns wallpapersDir;

        lockerCfg = {
          package = pkgs.swaylock;

          # On NixOS: add `security.pam.services.swaylock = {};` to the system configuration.
          # On non-NixOS: install `swaylock` from the distribution's repository.
          # See: https://nix-community.github.io/home-manager/options.xhtml#opt-programs.swaylock.enable
          lockerCmd = "swaylock -f";
        };

        screenshotCfg = {
          package = pkgs.grim;
          screenshotCmdFull = "${screenshotScript} full";
          screenshotCmdSelect = "${screenshotScript} select";
          screenshotCmdWindow = "${screenshotScript} window";
        };
      };
    };

    home.packages = with pkgs; [
      grim
      slurp
      wl-clipboard
      wlr-randr
    ];

    xsession.enable = true;
  };
}
