{ config, lib, pkgs, rootPath, ... }:

with lib;

let

  cfg = config.custom.base.agenix;

in

{
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
          "${secret}".file = rootPath + "/secrets/${secret}.age";
        })
        cfg.secrets);

      identityPaths = [
        "/root/.age/key.txt"
      ];
    };
  };
}
