# Authelia SSO Module

Adds Authelia as a centralized SSO provider for Traefik-exposed services.

## Features

- Native NixOS Authelia service with SQLite database
- Automatic Traefik middleware configuration
- Age-encrypted user management
- Trust local network (10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16)

## Configuration

### Enabling Authelia

In `nixos/roles/nas/default.nix`:

```nix
roles.nas.authelia.enable = true;
```

### Customizing Hostname

```nix
roles.nas.authelia.cookieDomain = "auth.local.harke.ch";
```

### Protected Services

By default, Authelia protects:

| Traefik Hostname           | Service     |
| -------------------------- | ----------- |
| `chat.local.harke.ch`      | open-webui  |
| `photos.local.harke.ch`    | immich      |
| `dms.local.harke.ch`       | paperless   |
| `library.local.harke.ch`   | calibre-web |
| `syncthing.local.harke.ch` | syncthing   |

## Setting Up Users

### 1. Create Age Public Key

```bash
age-keygen -o ~/.age/id.age -o ~/.age/pub.age
```

Copy `pub.age` to `secrets/nas/agepub.asc`.

### 2. Create User Configuration

Edit `secrets/nas/authelia-users.secrets`:

```yaml
users:
  admin:
    username: admin
    display_name: Administrator
    usernamePermutations:
      - admin
    email: admin@harke.ch
    primaryGroups:
      - authelia
    emailVerificationEnabled: true
    smtpSettings:
      disabled: true
```

### 3. Encrypt the Users File

```bash
cat secrets/nas/authelia-users.secrets | age -o - -r agepub.asc > secrets/nas/authelia-users.secrets.age
```

### 4. Configure in Nix

In your `home.nix` or `nixos-config.nix`:

```nix
age.secrets."authelia-users" = {
  source = config.age.secrets."authelia-users".path;
};
```

In `nixos/roles/nas/authelia/default.nix`:

```nix
let
  autheliaUsers = builtins.fromJSON (
    builtins.readFileToString (config.age.secrets."authelia-users".path)
  );
in
{
  services.authelia.users = autheliaUsers.users;
}
```

## Initial Setup

After enabling Authelia:

1. **Generate secrets:**

   ```bash
   nix develop --command sh -c '
     # Generate secret key
     nix run github:ryantm/authentik-cli generate-secret > /tmp/authelia-secret.txt

     # Generate admin password hash
     nix run github:ryantm/authentik-cli hash-password admin123 > /tmp/admin-password.txt
   '
   ```

2. **Update configuration** with generated secrets

3. **Rebuild and start:**

   ```bash
   sudo nixos-rebuild switch
   systemctl --user start authelia
   ```

4. **Access the Authelia UI:** `https://auth.local.harke.ch`

5. **Complete initial setup** in the browser (create users, configure SMTP if needed)

## Troubleshooting

### Authelia won't start

Check if the secrets file is being read:

```bash
journalctl -u authelia -f
```

### Services not redirecting to login

Ensure the middleware is referenced in the router config:

```nix
middlewares = [ "authelia" ];
```

### SSL certificate issues

Verify Let's Encrypt certificates are being issued:

```bash
journalctl -u traefik -f | grep -i cert
```

## Security Notes

- Keep `secretKey` and `adminPassword` encrypted in secrets
- Enable SMTP if you want email verification
- Consider 2FA after initial setup
- Regular users can be added via the Authelia UI or config
