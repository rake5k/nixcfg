# Authelia SSO

Centralised authentication for the services the NAS role exposes through Traefik. Authelia runs as
the `main` instance of the upstream NixOS module, backed by SQLite for persistent state and Redis
for sessions.

## Integration paths

Services reach Authelia in one of two ways, and the choice lives in the consuming role, not here.

**Forward auth.** The role's Traefik router lists the `authelia` middleware, which forwards each
request to `/api/authz/forward-auth` and passes `Remote-User`, `Remote-Groups`, `Remote-Name` and
`Remote-Email` back to the backend. Find the current set with:

```bash
grep -rn 'middlewares' --include='*.nix' nixos/roles/nas/ | grep authelia
```

**OIDC.** The application authenticates against Authelia's identity provider itself and its router
carries no middleware. Clients are defined in the `authelia-config-oidc-clients` secret; the
application side lives in its own role, such as `services.immich.settings.oauth` in
`../photos/default.nix`.

Both paths are subject to `config/access_control.yml`, which defaults to `deny` and grants access
per domain, network and group.

## Options

All options live under `custom.roles.nas.authelia`.

| Option                 | Default                            | Purpose                       |
| ---------------------- | ---------------------------------- | ----------------------------- |
| `enable`               | `false`                            | Enable the instance           |
| `host`                 | `auth.local.harke.ch`              | Host name of the portal       |
| `jwtSecret`            | `authelia-jwt-secret`              | Password reset JWT secret     |
| `oidcHmacSecret`       | `authelia-oidc-hmac-secret`        | HMAC secret signing OIDC JWTs |
| `oidcIssuerPrivateKey` | `authelia-oidc-issuer-private-key` | OIDC issuer private key       |
| `sessionSecret`        | `authelia-session-secret`          | Encrypts session data         |
| `storageEncryptionKey` | `authelia-storage-encryption-key`  | Encrypts the SQLite database  |

Each option names an agenix secret rather than holding a value. The role registers the names in
`custom.base.agenix.secrets` and chowns them to the instance user.

Two further secrets are not exposed as options because they are whole configuration fragments rather
than single values: `authelia-config-notifier` and `authelia-config-oidc-clients`. Both are passed
to Authelia as additional settings files.

## Session storage

Authelia's default session provider holds sessions in the process, so restarting the unit logs every
user out. The role runs a dedicated `services.redis.servers.authelia` instance instead, listening on
`/run/redis-authelia/redis.sock` with TCP disabled. Redis keeps the nixpkgs default RDB schedule, so
sessions also survive a reboot.

The socket path appears twice — as `redisSocket` in `default.nix` and as `session.redis.host` in
`config/session.yml` — because the YAML cannot reference Nix. Change both together.

Session lifetimes are set in `config/session.yml`. With `inactivity` at `5m`, an idle session ends
after five minutes regardless of the backend; Redis changes what happens to sessions that are still
alive when the unit restarts.

## Managing users

The authentication backend is a file, `/var/lib/authelia-main/users_database.yml`, hashed with
argon2id and watched for changes, so edits take effect without a restart.

`authelia-create-user` appends an entry interactively:

```bash
authelia-create-user <username> <email> [group1,group2,...]
```

Groups default to `users`. `config/access_control.yml` grants the wider set of hosts to
`group:admins`.

The `authelia` package is also on `PATH` for `authelia crypto hash generate` and the `storage`
subcommands.

## Files

| Path                                | Contents                                      |
| ----------------------------------- | --------------------------------------------- |
| `config/access_control.yml`         | Default-deny rules per domain, network, group |
| `config/authentication_backend.yml` | File backend and argon2id parameters          |
| `config/ntp.yml`                    | NTP server used for the clock skew check      |
| `config/session.yml`                | Cookie domain, lifetimes, Redis provider      |
| `config/storage.yml`                | SQLite database path                          |

The whole `config/` directory is passed to Authelia, along with the two secret settings files.
Authelia deep-merges them, and files listed later win on conflicting keys.

State lives in `/var/lib/authelia-main` (SQLite, user database) and `/var/lib/redis-authelia`
(sessions), both persisted across the impermanence rollback.

## Troubleshooting

Check the config as the service sees it. The unit already runs `validate-config` as `ExecStartPre`,
so the file list to reuse is in the unit itself:

```bash
systemctl cat authelia-main | grep ExecStart
```

Service and unit state:

```bash
journalctl -u authelia-main -f
systemctl status redis-authelia
```

Confirm sessions are reaching Redis rather than falling back to memory:

```bash
sudo redis-cli -s /run/redis-authelia/redis.sock dbsize
```

A user who is logged out on every restart of `authelia-main` indicates the Redis provider is not
being picked up — check that `session.redis` survived the settings-file merge.
