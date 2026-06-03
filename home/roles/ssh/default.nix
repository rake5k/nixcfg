{
  config,
  lib,
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

    programs.ssh = {
      enable = true;

      # Opt out of the deprecated implicit defaults and keep the previous
      # values explicitly on the wildcard host.
      enableDefaultConfig = false;
      settings."*" = {
        ForwardAgent = false;
        AddKeysToAgent = "no";
        Compression = false;
        ServerAliveInterval = 0;
        ServerAliveCountMax = 3;
        HashKnownHosts = false;
        UserKnownHostsFile = "~/.ssh/known_hosts";
        ControlMaster = "no";
        ControlPath = "~/.ssh/master-%r@%n:%p";
        ControlPersist = "no";
      };
    };

    homeage.file = listToAttrs (map mkHomeageFile cfg.identities);
  };
}
