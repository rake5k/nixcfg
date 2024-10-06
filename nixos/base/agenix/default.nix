{ config, lib, inputs, ... }:

with lib;

let

  cfg = config.custom.base.agenix;

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
      secrets = mkMerge (builtins.map
        (secret: {
          "${secret}".file = "${cfg.secretsBasePath}/${secret}.age";
        })
        cfg.secrets);

      identityPaths = [
        "/root/.age/key.txt"
      ];
    };
  };
}
