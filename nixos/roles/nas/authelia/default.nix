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

  oidcClientConfig = "authelia-config-oidc-clients";

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

      host = mkOption {
        type = types.str;
        default = "auth.local.harke.ch";
        description = "Host name where Authelia is available on";
      };

      jwtSecret = mkOption {
        type = types.str;
        default = "authelia-jwt-secret";
        description = ''
          Name of the JWT secret.
        '';
      };

      oidcHmacSecret = mkOption {
        type = types.str;
        default = "authelia-oidc-hmac-secret";
        description = ''
          Name of the HMAC secret used to sign OIDC JWTs.
        '';
      };

      oidcIssuerPrivateKey = mkOption {
        type = types.str;
        default = "authelia-oidc-issuer-private-key";
        description = ''
          Name of the private key file used to encrypt OIDC JWTs.
        '';
      };

      storageEncryptionKey = mkOption {
        type = types.str;
        default = "authelia-storage-encryption-key";
        description = ''
          Name of the storage encryption key secret.
        '';
      };
    };
  };

  config = mkIf cfg.enable {

    age.secrets = mkSecretOwner [
      cfg.jwtSecret
      cfg.oidcHmacSecret
      cfg.oidcIssuerPrivateKey
      cfg.storageEncryptionKey
      oidcClientConfig
    ];

    custom.base = {
      agenix.secrets = [
        cfg.jwtSecret
        cfg.oidcHmacSecret
        cfg.oidcIssuerPrivateKey
        cfg.storageEncryptionKey
        oidcClientConfig
      ];
      system.btrfs.impermanence.extraDirectories = [ dataDir ];
    };

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
        secrets = {
          jwtSecretFile = mkSecretFilePath cfg.jwtSecret;
          oidcHmacSecretFile = mkSecretFilePath cfg.oidcHmacSecret;
          oidcIssuerPrivateKeyFile = mkSecretFilePath cfg.oidcIssuerPrivateKey;
          storageEncryptionKeyFile = mkSecretFilePath cfg.storageEncryptionKey;
        };
        settings.theme = "auto";
        settingsFiles = [
          ./config
          (mkSecretFilePath oidcClientConfig)
        ];
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
            rule = "Host(`${cfg.host}`)";
            service = "authelia";
            tls.certResolver = "letsencrypt";
          };
        };
      };
    };
  };
}
