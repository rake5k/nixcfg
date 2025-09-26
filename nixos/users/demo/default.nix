{ config, lib, ... }:

let

  inherit (config.custom.base) users;
  inherit (lib) elem mkIf;

  username = "demo";
  secretSmb = "smb-home-${username}";

  isEnabled = elem username users;

in

mkIf isEnabled {
  custom.base.agenix.secrets = [ secretSmb ];

  fileSystems =
    let
      target = "/mnt/${username}";
      fileserver = "hyperion";
      fsType = "cifs";
      credentials = config.age.secrets."${secretSmb}".path;
      automount_opts = [
        "x-systemd.automount"
        "noauto"
        "x-systemd.idle-timeout=60"
        "x-systemd.device-timeout=5s"
        "x-systemd.mount-timeout=5s"
      ];
      auth_opts = [
        "uid=${toString config.users.users."${username}".uid}"
        "gid=100"
        "dir_mode=0700"
        "file_mode=0700"
        "credentials=${credentials}"
      ];
      options = automount_opts ++ auth_opts;
    in
    {
      "${target}/home" = {
        device = "//${fileserver}/${username}";
        inherit fsType;
        inherit options;
      };

      "${target}/private" = {
        device = "//${fileserver}/private";
        inherit fsType;
        inherit options;
      };

      "${target}/public" = {
        device = "//${fileserver}/public";
        inherit fsType;
        inherit options;
      };
    };

  users.users."${username}" = {
    name = username;
    isNormalUser = true;
    uid = 1001;
    extraGroups = [
      "audio"
      "video"
      "scanner"
      "dialout"
    ];
    initialPassword = "changeme";
  };
}
