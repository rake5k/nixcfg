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
  };
}
