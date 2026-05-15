{
  config,
  lib,
  pkgs,
  ...
}:

let

  inherit (lib)
    genAttrs
    getExe
    mkEnableOption
    mkIf
    mkOption
    types
    ;

  cfg = config.custom.roles.nas.authelia;

  dataDir = "/var/lib/authelia-main";

  hasSecrets = cfg.jwtSecret != null && cfg.storageEncryptionKey != null;
  mkSecretFilePath = secret: config.age.secrets."${secret}".path;
  mkSecretOwner =
    secrets:
    genAttrs secrets (_name: {
      owner = config.services.authelia.instances.main.user;
      inherit (config.services.authelia.instances.main) group;
    });

in

{
  options = {
    custom.roles.nas.authelia = {
      enable = mkEnableOption "Authelia SSO";

      jwtSecret = mkOption {
        type = with types; nullOr str;
        default = null;
        description = ''
          Name of the JWT secret.
        '';
      };

      storageEncryptionKey = mkOption {
        type = with types; nullOr str;
        default = null;
        description = ''
          Name of the storage encryption key secret.
        '';
      };
    };
  };

  config = mkIf cfg.enable {

    age.secrets = mkIf hasSecrets (
      mkSecretOwner (
        with cfg;
        [
          jwtSecret
          storageEncryptionKey
        ]
      )
    );

    custom.base.system.btrfs.impermanence.extraDirectories = [ dataDir ];

    # Authelia admin tool
    environment.systemPackages = [
      (pkgs.writeShellScriptBin "authelia-create-user" ''
        set -e

        if [ $# -lt 2 ]; then
          echo "Usage: authelia-create-user <username> <email> [groups]"
          exit 1
        fi

        USERNAME="$1"
        EMAIL="$2"
        GROUPS="''${3:-users}"
        USERS_FILE="${dataDir}/users_database.yml"

        echo "Creating user: $USERNAME ($EMAIL)"
        read -s -p "Password: " PASSWORD
        echo ""

        HASH=$(${getExe pkgs.authelia} crypto hash generate argon2 --password "$PASSWORD" 2>/dev/null | grep "Digest:" | awk '{print $2}')

        if grep -q "^  $USERNAME:" "$USERS_FILE" 2>/dev/null; then
          echo "User $USERNAME already exists!"
          exit 1
        fi

        cat >> "$USERS_FILE" << EOF
          $USERNAME:
            displayname: "$USERNAME"
            password: "$HASH"
            email: "$EMAIL"
            groups:
              - $GROUPS
        EOF

        echo "User $USERNAME created successfully!"
      '')
    ];

    services = {
      authelia.instances.main = {
        enable = true;
        secrets =
          if hasSecrets then
            {
              jwtSecretFile = mkSecretFilePath cfg.jwtSecret;
              storageEncryptionKeyFile = mkSecretFilePath cfg.storageEncryptionKey;
            }
          else
            {
              manual = true;
            };
        settings.theme = "auto";
        settingsFiles = [ ./config ];
      };

      traefik.dynamicConfigOptions.http = {
        middlewares = {
          authelia = {
            forwardAuth = {
              address = "http://localhost:9091/api/authz/forward-auth";
              trustForwardHeader = true;
              authResponseHeaders = [
                "Remote-User"
                "Remote-Groups"
                "Remote-Name"
                "Remote-Email"
              ];
            };
          };
        };

        services = {
          authelia.loadBalancer.servers = [
            { url = "http://localhost:9091"; }
          ];
        };

        routers = {
          authelia = {
            entryPoints = [ "websecure" ];
            rule = "Host(`auth.local.harke.ch`)";
            service = "authelia";
            tls.certResolver = "letsencrypt";
          };
        };
      };
    };
  };
}
