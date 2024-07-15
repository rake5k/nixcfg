{ config, lib, inputs, ... }:

with lib;

let

  cfg = config.custom.base.agenix;

in

{
  imports = [ inputs.agenix.nixosModules.age ];

  options = {
    custom.base.agenix.secrets = mkOption {
      type = with types; listOf str;
      default = [ ];
      description = ''
        Secrets to install.
      '';
    };
  };

  config = {
    age = {
      secrets = mkMerge (builtins.map
        (secret: {
          "${secret}".file = "${inputs.self}/secrets/${secret}.age";
        })
        cfg.secrets);

      identityPaths = [
        "/root/.age/key.txt"
      ];
    };
  };
}
