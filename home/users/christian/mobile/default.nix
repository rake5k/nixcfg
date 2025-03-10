{ config, lib, ... }:

let

  cfg = config.custom.users.christian.mobile;

  inherit (lib) mkEnableOption mkIf;

in

{
  options = {
    custom.users.christian.mobile = {
      enable = mkEnableOption "Mobile";
    };
  };

  config = mkIf cfg.enable {
    custom.roles.ssh = {
      enable = true;
      identities = [
        "id_logseq"
        "id_logseq.pub"
      ];
    };

    home.file = {
      "bin/pull-notes-home" = {
        source = ./scripts/pull-notes-home;
        executable = true;
      };
      "bin/push-notes-home" = {
        source = ./scripts/push-notes-home;
        executable = true;
      };
    };
  };
}
