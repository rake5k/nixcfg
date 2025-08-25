{
  config,
  lib,
  pkgs,
  ...
}:

let

  cfg = config.custom.roles.ssh;

  inherit (lib)
    mkEnableOption
    mkIf
    mkOption
    listToAttrs
    nameValuePair
    types
    ;

  sshDirectory = "${config.home.homeDirectory}/.ssh";
  mkHomeageFile =
    identity:
    nameValuePair identity {
      source = "${config.custom.roles.homeage.secretsSourcePath}/${identity}.age";
      symlinks = [ "${sshDirectory}/${identity}" ];
    };

  inherit (pkgs.stdenv) isLinux;

in

{
  options = {
    custom.roles.ssh = {
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

    home.packages = with pkgs; [ openssh ];

    homeage.file = listToAttrs (map mkHomeageFile cfg.identities);

    services.ssh-agent.enable = isLinux;
  };
}
