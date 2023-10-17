{ config, lib, pkgs, inputs, ... }:

with lib;

let

  cfg = config.custom.roles.homeage;

  mkHomeageFile = secret: nameValuePair secret {
    source = "${cfg.secretsSourcePath}/${secret}.age";
    symlinks = [ "${cfg.secretsPath}/${secret}" ];
  };

in

{
  options = {
    custom.roles.homeage = {
      enable = mkEnableOption "Homeage secrets management";

      secrets = mkOption {
        type = with types; listOf str;
        default = [ ];
        description = "Secrets to install.";
      };

      secretsSourcePath = mkOption {
        type = types.path;
        default = "${inputs.self}/secrets/${config.home.username}";
        description = "Default source path of the encrypted files.";
      };

      secretsPath = mkOption {
        type = types.path;
        default = "${config.xdg.dataHome}/secrets";
        description = "Base path of the secret symlinks.";
      };
    };
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      age
      agenix-cli
    ];

    homeage = {
      identityPaths = [ "${config.home.homeDirectory}/.age/key.txt" ];
      installationType = mkDefault "systemd";
      file = builtins.listToAttrs (map mkHomeageFile cfg.secrets);
    };
  };
}
