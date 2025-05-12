{ config, lib, ... }:

let

  cfg = config.custom.roles.nas.sunshine;

  inherit (lib)
    mkEnableOption
    mkIf
    mkOption
    types
    ;

in

{
  options = {
    custom.roles.nas.sunshine = {
      enable = mkEnableOption "Sunshine config";

      dataPath = mkOption {
        type = types.path;
        default = "/data/container/sunshine";
        description = "Path where the Sunshine data lies";
      };
    };
  };

  config = mkIf cfg.enable {

    # Allow Sunshine ports
    networking.firewall = {
      enable = true;
      allowedTCPPorts = [
        47984
        47989
        48010
      ];
      allowedUDPPorts = [
        47998
        47999
        48000
        48002
        48010
      ];
    };

    users = {
      users = {
        sunshine = {
          group = "sunshine";
          # Grant access to render device (/dev/dri/renderD128).
          extraGroups = [ "render" ];
          isSystemUser = true;
        };
      };
      groups.sunshine = { };
    };

    virtualisation.oci-containers =
      let
        uidStr = toString config.users.users.sunshine.uid;
        gidStr = toString config.users.groups.sunshine.gid;
      in
      {
        containers = {
          sunshine = {
            image = "docker.io/heywoodlh/sunshine:latest";
            environment = {
              PUID = uidStr;
              PGID = gidStr;
              TZ = "Europe/Zurich";
            };
            user = "${uidStr}:${gidStr}";
            volumes = [
              "${cfg.dataPath}/config:/config"
              "${cfg.dataPath}/steam:/steam"
            ];
            extraOptions = [
              "--gpus=all"
              "--network=host"
              "--hostname=sunshine-docker"
              "--memory=8g"
            ];
          };
        };
      };

    systemd.tmpfiles.rules = [
      "d ${cfg.dataPath}/config 0755 ${config.users.users.sunshine.name} ${config.users.users.sunshine.group} -"
      "d ${cfg.dataPath}/steam 0755 ${config.users.users.sunshine.name} ${config.users.users.sunshine.group} -"
    ];
  };
}
