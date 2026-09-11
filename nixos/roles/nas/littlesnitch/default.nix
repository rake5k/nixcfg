{ config, lib, ... }:

let

  cfg = config.custom.roles.nas.littlesnitch;

  inherit (lib)
    mkEnableOption
    mkIf
    mkOption
    types
    ;

  port = 3031;
  localUrl = "http://localhost:${toString port}";
  remoteUrl = "https://${cfg.host}";

in

{
  options = {
    custom.roles.nas.littlesnitch = {
      enable = mkEnableOption "Little Snitch config";

      host = mkOption {
        type = types.str;
        default = "littlesnitch.local.harke.ch";
        description = "Host name where the Little Snitch web interface is available on";
      };
    };
  };

  config = mkIf cfg.enable {
    custom.programs.littlesnitch = {
      enable = true;

      # Getting the eBPF programs past the verifier takes around 45 seconds,
      # and holding back network-pre.target for that long would put every
      # service on this host behind it on each boot. The cost is that whatever
      # connects in that window is listed as "Not Identified".
      startBeforeNetwork = false;

      # The daemon stays on loopback and Authelia in front of Traefik does the
      # authenticating: the musl binary carries no libpam, so the web UI's own
      # `system_account` authentication is not available. Its WebSocket upgrade
      # is checked against `ui_base_urls`, which therefore has to carry the
      # proxied name as well — otherwise the UI sits at "Daemon offline".
      settings.web_ui.ui_base_urls = [
        remoteUrl
        localUrl
        "http://127.0.0.1:${toString port}"
      ];
    };

    custom.roles.nas.dashboard.services = [
      {
        "Little Snitch" = {
          icon = "mdi-shield-lock-outline";
          href = remoteUrl;
          siteMonitor = localUrl;
        };
      }
    ];

    services.traefik.dynamicConfigOptions.http = {
      services.littlesnitch.loadBalancer.servers = [
        { url = localUrl; }
      ];

      routers.littlesnitch = {
        entryPoints = [ "websecure" ];
        rule = "Host(`${cfg.host}`)";
        service = "littlesnitch";
        tls.certResolver = "letsencrypt";
        middlewares = [ "authelia" ];
      };
    };
  };
}
