{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let

  cfg = config.custom.roles.dev.java;

  java = pkgs.jdk;
  visualvm = pkgs.visualvm.override { jdk = pkgs.jdk8; };

  inherit (config.custom.roles.homeage) secretsPath;
  codeGenomeSecrets = filter (s: s != null) [
    cfg.codeGenome.usernameSecret
    cfg.codeGenome.tokenSecret
  ];
  codeGenomeEnabled = length codeGenomeSecrets == 2;

  mkSecretOption =
    what:
    mkOption {
      type = with types; nullOr str;
      default = null;
      description = ''
        Name of the homeage secret holding the Code Genome Project ${what}. Together with the
        token this exposes the decrypted file to Gradle through the CODE_GENOME_*_FILE
        variables read by the OpenRewrite init script.
      '';
    };

in

{
  options = {
    custom.roles.dev.java = {
      enable = mkEnableOption "Java";

      codeGenome = {
        usernameSecret = mkSecretOption "username";
        tokenSecret = mkSecretOption "download token";
      };
    };
  };

  config = mkIf cfg.enable (mkMerge [
    {
      assertions = [
        {
          assertion = codeGenomeSecrets == [ ] || codeGenomeEnabled;
          message = "custom.roles.dev.java.codeGenome needs both usernameSecret and tokenSecret.";
        }
      ];

      home = {
        packages = [
          java
          visualvm
        ];

        sessionVariables = {
          JAVA_HOME = "${java}/lib/openjdk";
          JDK_HOME = "${java}/lib/openjdk";
        };

        file.".gradle" = {
          recursive = true;
          source = ./gradle;
        };
      };
    }

    (mkIf codeGenomeEnabled {
      custom.roles.homeage = {
        enable = true;
        secrets = codeGenomeSecrets;
      };

      home.sessionVariables = {
        CODE_GENOME_USERNAME_FILE = "${secretsPath}/${cfg.codeGenome.usernameSecret}";
        CODE_GENOME_TOKEN_FILE = "${secretsPath}/${cfg.codeGenome.tokenSecret}";
      };
    })
  ]);
}
