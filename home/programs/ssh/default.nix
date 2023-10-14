{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.custom.programs.ssh;

  inherit (config.custom.roles.homeage) secretsPath;
  sshDirectory = ".ssh";
  mkFileEntry = identity: {
    name = "${sshDirectory}/${identity}";
    value = { source = "${secretsPath}/${identity}"; };
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
    custom.roles.homeage.secrets = cfg.identities;
    home.file = listToAttrs (map mkFileEntry cfg.identities);
    programs.ssh.enable = true;
  };
}
