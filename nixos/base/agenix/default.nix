{
  config,
  lib,
  inputs,
  ...
}:

let

  cfg = config.custom.base.agenix;

  inherit (lib)
    mkMerge
    mkOption
    optionalString
    types
    ;

  useImpermanence = config.custom.base.system.btrfs.impermanence.enable;
  hostKeyFile = "/etc/ssh/ssh_host_ed25519_key";

in

{
  imports = [ inputs.agenix.nixosModules.age ];

  options = {
    custom.base.agenix = {
      secretsBasePath = mkOption {
        type = types.str;
        default = "${inputs.self}/secrets/nixos";
        description = ''
          Base path to the system secrets.
        '';
      };

      secrets = mkOption {
        type = with types; listOf str;
        default = [ ];
        description = ''
          Secrets to install.
        '';
      };
    };
  };

  config = {
    age = {
      secrets = mkMerge (
        builtins.map (secret: { "${secret}".file = "${cfg.secretsBasePath}/${secret}.age"; }) cfg.secrets
      );

      identityPaths = [
        "${optionalString useImpermanence "/persist"}${hostKeyFile}"
      ];
    };

    programs.ssh.extraConfig = ''
      Host code.harke.ch
        IdentityFile ${hostKeyFile}
    '';
  };
}
