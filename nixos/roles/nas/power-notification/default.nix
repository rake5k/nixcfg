{
  config,
  lib,
  pkgs,
  ...
}:

let

  nasCfg = config.custom.roles.nas;
  cfg = nasCfg.power-notification;

  inherit (config.custom.base) hostname;
  inherit (config.lib.custom)
    mkNtfyCommand
    ntfyTokenSecret
    ntfyUrlSecret
    ;
  inherit (lib) mkEnableOption mkIf toUpper;

  prettyHostname = "${toUpper hostname}";

  ntfyWakeUpAction = {
    action = "view";
    label = "Wake up";
    url = "http://sv-syno-01:8090/";
    clear = true;
  };

  ntfyCheckStatusAction = {
    action = "view";
    label = "Check status";
    url = "https://${nasCfg.glances.host}/";
    clear = true;
  };

  notifySleep = mkNtfyCommand config.age.secrets {
    title = "${prettyHostname} is going to save some power...";
    message = "See you later!";
    tags = [ "zzz" ];
    actions = [ ntfyWakeUpAction ];
  };

  notifyShutdown = mkNtfyCommand config.age.secrets {
    title = "${prettyHostname} is going to shut down...";
    message = "Bye bye!";
    tags = [ "electric_plug" ];
    actions = [ ntfyWakeUpAction ];
  };

  notifyStartup = mkNtfyCommand config.age.secrets {
    title = "${prettyHostname} is ready to serve data";
    message = "Let's goo!";
    tags = [ "floppy_disk" ];
    actions = [ ntfyCheckStatusAction ];
  };

in

{
  options = {
    custom.roles.nas.power-notification = {
      enable = mkEnableOption "Power notification";
    };
  };

  config = mkIf cfg.enable {
    custom.base.agenix.secrets = [
      ntfyTokenSecret
      ntfyUrlSecret
    ];

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
  };
}
