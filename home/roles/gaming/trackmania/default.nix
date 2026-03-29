{
  lib,
  config,
  ...
}:

let

  cfg = config.custom.roles.gaming.trackmania;

in

{
  options = {
    custom.roles.gaming.trackmania = {
      enable = lib.mkEnableOption "TrackMania";
    };
  };

  config = lib.mkIf cfg.enable {
    services = {
      syncthing = {
        settings = {
          folders = {
            TrackMania = {
              enable = true;
              devices = [ config.services.syncthing.settings.devices.hyperion.name ];
              id = "flgrz-5ytrt";
              path = "~/.steam/steam/steamapps/compatdata/11020/pfx/drive_c/users/steamuser/Documents/TrackMania/Profiles";
            };
          };
        };
      };
    };
  };
}
