{
  config,
  lib,
  pkgs,
  ...
}:

let

  cfg = config.custom.roles.nas;

  inherit (lib)
    getExe
    mkEnableOption
    mkIf
    toUpper
    ;
  inherit (config.custom.base) hostname;

  prettyHostname = "${toUpper hostname}";

  ntfyTopic = "chris-alerts";
  ntfyTokenSecret = "${config.custom.base.hostname}/ntfy-token";
  ntfyUrlSecret = "${config.custom.base.hostname}/ntfy-url";

  ntfyWakeUpAction = {
    action = "view";
    label = "Wake up";
    url = "http://sv-syno-01:8090/";
    clear = true;
  };

  glancesPort = toString config.services.glances.port;
  ntfyCheckStatusAction = {
    action = "view";
    label = "Check status";
    url = "http://${hostname}:${glancesPort}/";
    clear = true;
  };

  mkNtfyCommand =
    body:
    let
      jsonBody = builtins.toJSON (body // { topic = ntfyTopic; });
      bodyFile = pkgs.writeText "ntfyBody" jsonBody;
    in
    ''
      ${getExe pkgs.curl} \
        -H "Authorization:Bearer $(${pkgs.coreutils}/bin/cat ${
          config.age.secrets.${ntfyTokenSecret}.path
        })" \
        -H "Markdown: yes" \
        -H "Content-Type: application/json" \
        -d @'${bodyFile}' \
        "$(${pkgs.coreutils}/bin/cat ${config.age.secrets.${ntfyUrlSecret}.path})"
    '';

  notifySleep = mkNtfyCommand {
    title = "${prettyHostname} is going to save some power...";
    message = "See you later!";
    tags = [ "zzz" ];
    actions = [ ntfyWakeUpAction ];
  };

  notifyShutdown = mkNtfyCommand {
    title = "${prettyHostname} is going to shut down...";
    message = "Bye bye!";
    tags = [ "electric_plug" ];
    actions = [ ntfyWakeUpAction ];
  };

  notifyStartup = mkNtfyCommand {
    title = "${prettyHostname} is ready to serve data";
    message = "Let's goo!";
    tags = [ "floppy_disk" ];
    actions = [ ntfyCheckStatusAction ];
  };

in

{
  options = {
    custom.roles.nas = {
      enable = mkEnableOption "NAS config";
    };
  };

  config = mkIf cfg.enable {
    custom = {
      base = {
        agenix.secrets = [
          ntfyTokenSecret
          ntfyUrlSecret
        ];

        system = {
          boot.secureBoot = true;
          btrfs.impermanence.enable = true;
          luks.remoteUnlock = true;
          network.wol.enable = true;
        };
      };

      roles.nas = {
        plex.enable = true;
        syncthing.enable = true;
      };
    };

    powerManagement = {
      # pre-sleep-notification:
      powerDownCommands = ''
        ${notifySleep}
      '';

      # post-resume-notification:
      powerUpCommands = ''
        ${notifyStartup}
      '';
    };

    systemd.services = {
      pre-shutdown-notification = {
        description = "Pre-Shutdown Notification";
        wantedBy = [ "multi-user.target" ];
        wants = [ "run-agenix.d.mount" ];
        bindsTo = [ "network-online.target" ];
        after = [ "network-online.target" ];
        before = [
          "shutdown.target"
          "reboot.target"
          "halt.target"
        ];
        script = ''
          ${pkgs.coreutils}/bin/true
        '';
        preStop = ''
          ${notifyShutdown}
        '';
        serviceConfig = {
          RemainAfterExit = true;
          TimeoutStopSec = 10;
        };
      };

      post-startup-notification = {
        description = "Post-Startup Notification";
        startLimitIntervalSec = 120;
        startLimitBurst = 5;
        wantedBy = [ "multi-user.target" ];
        wants = [
          "network-online.target"
          "run-agenix.d.mount"
        ];
        after = [ "multi-user.target" ];
        script = ''
          ${notifyStartup}
        '';
        serviceConfig = {
          Type = "oneshot";
          Restart = "on-failure";
          RestartSec = 10;
        };
      };

      # Fix post-resume service failing with status `6/NOTCONFIGURED`
      post-resume = {
        startLimitIntervalSec = 120;
        startLimitBurst = 5;
        after = [
          "network-online.target"
          "run-agenix.d.mount"
        ];
        wants = [
          "network-online.target"
          "run-agenix.d.mount"
        ];
        serviceConfig = {
          Restart = "on-failure";
          RestartSec = 10;
        };
      };
    };

    services.glances = {
      enable = true;
      openFirewall = true;
    };
  };
}
