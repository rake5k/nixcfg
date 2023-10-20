{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.custom.users.christian.mobile;

  logseqSshKey = "id_logseq";
  logseqSshPubKey = "${logseqSshKey}.pub";

in

{
  options = {
    custom.users.christian.mobile = {
      enable = mkEnableOption "Mobile";
    };
  };

  config = mkIf cfg.enable {
    custom = {
      programs.ssh = {
        enable = true;
        identities = [ logseqSshKey logseqSshPubKey ];
      };
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
