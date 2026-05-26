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
    hm
    literalExpression
    mkEnableOption
    mkIf
    mkOption
    types
    ;

  windowManagerSessions = {
    niri = {
      name = "Niri";
      comment = "A scrollable-tiling Wayland compositor";
      exec = "${config.home.homeDirectory}/.nix-profile/bin/niri-session";
      desktopName = "niri";
    };
    river = {
      name = "River";
      comment = "A dynamic tiling Wayland compositor";
      exec = "${config.home.homeDirectory}/.nix-profile/bin/river";
      desktopName = "river";
    };
  };

  activeSession = windowManagerSessions.${cfg.windowManager};

  # On NixOS: add `security.pam.services.swaylock = {};` to the system configuration.
  # On non-NixOS: install `swaylock` from the distribution's repository.
  # See: https://nix-community.github.io/home-manager/options.xhtml#opt-programs.swaylock.enable
  swaylockPkg = if config.custom.base.non-nixos.enable then null else pkgs.swaylock;
  lockerCfg = {
    package = swaylockPkg;
    lockerCmd = "swaylock -f";
  };

  screenshotScript = pkgs.writeShellScript "wayland-screenshot" ''
    set -uo pipefail

    notify_success() {
      ${pkgs.libnotify}/bin/notify-send -u low "''${1}" "''${2}"
    }

    notify_failure() {
      ${pkgs.libnotify}/bin/notify-send -u critical "Taking screenshot failed" "''${1}"
    }

    copy_to_clipboard_and_notify() {
      local file="''${1}"
      local message="''${2}"
      ${pkgs.wl-clipboard}/bin/wl-copy < "''${file}"
      notify_success "''${message}" "''${file}"
    }

    screenshot() {
      OUTDIR="''${HOME}/Pictures/Screenshots"
      OUT="''${OUTDIR}/Screenshot from $(${pkgs.coreutils}/bin/date '+%Y-%m-%d %H-%M-%S').png"

      ${pkgs.coreutils}/bin/mkdir -p "''${OUTDIR}"

      case $1 in
      full)
        if ${getExe pkgs.grim} "''${OUT}"; then
          copy_to_clipboard_and_notify "''${OUT}" "Fullscreen screenshot saved"
        else
          notify_failure "Fullscreen screenshot failed"
        fi
      ;;
      select)
        ${pkgs.coreutils}/bin/sleep 0.5
        GEOMETRY="$(${getExe pkgs.slurp} -d)"
        if [[ -n "''${GEOMETRY}" ]]; then
          if ${getExe pkgs.grim} -g "''${GEOMETRY}" "''${OUT}"; then
            copy_to_clipboard_and_notify "''${OUT}" "Selection screenshot saved"
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
            copy_to_clipboard_and_notify "''${OUT}" "Window screenshot saved"
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

      windowManager = mkOption {
        type = types.enum [
          "river"
          "niri"
        ];
        default = "niri";
        description = "The Wayland window manager to use";
      };

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

      # Window managers

      niri = mkIf (cfg.windowManager == "niri") {
        inherit lockerCfg;
        inherit (cfg) autoruns wallpapersDir;
        enable = true;
      };

      river = mkIf (cfg.windowManager == "river") {
        inherit lockerCfg;
        inherit (cfg) autoruns wallpapersDir;
        enable = true;

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

    programs = {
      # supporting tools
      fuzzel = {
        enable = true;
        settings = {
          main = {
            dpi-aware = "no";
            layer = "overlay";
            list-executables-in-path = "yes";
            terminal = "${getExe pkgs.kitty}";
          };
        };
      };

      swaylock = {
        enable = true;
        package = swaylockPkg;
        settings = {
          show-failed-attempts = true;
          show-keyboard-layout = true;
        };
      };
    };

    home.activation = mkIf config.custom.base.non-nixos.enable {
      waylandSessionGuide = hm.dag.entryAfter [ "writeBoundary" ] ''
        cat <<'GUIDE'

        ============================================================
         Register the ${activeSession.name} session with GDM
        ============================================================
         GDM only scans /usr/share/wayland-sessions and
         /usr/local/share/wayland-sessions for .desktop files. It
         cannot resolve binaries from ~/.nix-profile, so the session
         file must point at the absolute path.

         Run once (re-run if the binary path changes):

        sudo install -d /usr/local/share/wayland-sessions
        sudo tee /usr/local/share/wayland-sessions/${activeSession.desktopName}.desktop >/dev/null <<'DESKTOP'
        [Desktop Entry]
        Name=${activeSession.name}
        Comment=${activeSession.comment}
        Exec=${activeSession.exec}
        Type=Application
        DesktopNames=${activeSession.desktopName}
        DESKTOP

         Then log out and pick "${activeSession.name}" from the gear
         menu on the GDM login screen.
        ============================================================
        GUIDE
      '';
    };
  };
}
