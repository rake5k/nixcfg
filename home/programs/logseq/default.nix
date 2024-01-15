{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.custom.programs.logseq;

  sshKey = "id_logseq";
  sshPubKey = "${sshKey}.pub";

in

{
  options = {
    custom.programs.logseq = {
      enable = mkEnableOption "Logseq";
    };
  };

  config = mkIf cfg.enable {

    custom = {
      programs.ssh = {
        enable = true;
        identities = [ sshKey sshPubKey ];
      };
    };

    home.packages = [ pkgs.unstable.logseq ];
  };
}
