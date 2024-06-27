{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.custom.programs.ssh;

  sshDirectory = "${config.home.homeDirectory}/.ssh";
  mkHomeageFile = identity: nameValuePair identity {
    source = "${config.custom.roles.homeage.secretsSourcePath}/${identity}.age";
    symlinks = [ "${sshDirectory}/${identity}" ];
  };

in

{
  options = {
    custom.programs.ssh = {
      enable = mkEnableOption "SSH client";

      identities = mkOption {
        type = with types; listOf str;
        default = [ ];
        description = "SSH identities managed by homeage";
      };
    };
  };

  config = mkIf cfg.enable {
    custom.roles.homeage.enable = true;

    homeage.file = listToAttrs (map mkHomeageFile cfg.identities);
    programs.ssh = {
      enable = true;
      controlMaster = "auto";
      controlPath = "~/.ssh/master-%r@%n:%p";
      controlPersist = "10m";
    };
  };
}
