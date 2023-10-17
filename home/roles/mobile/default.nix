{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.custom.roles.mobile;

  logseqSshKey = "id_logseq";
  logseqSshPubKey = "${logseqSshKey}.pub";

in

{
  options = {
    custom.roles.mobile = {
      enable = mkEnableOption "Mobile";
    };
  };

  config = mkIf cfg.enable {
    homeage = {
      installationType = "activation";
      mount = "${config.xdg.dataHome}/homeage";
    };

    custom = {
      base.nix-on-droid.enable = true;

      programs.ssh = {
        enable = true;
        identities = [ logseqSshKey logseqSshPubKey ];
      };

      roles = {
        mobile.bin.enable = true;
      };
    };
  };
}
