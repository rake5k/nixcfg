# :snowflake: Nix Configuration

[![NixOS][nixos-badge]][nixos]
[![Build and Test][ci-badge]][ci]

## Features

* Automation scripts to setup a fresh [NixOS machine from scratch](flake/apps/nixos-install.sh) or
  an [arbitrary preinstalled Linux machine](flake/apps/setup.sh) easily
* Disk configuration using [Disko][disko]
* Secret management in [NixOS][nixos] ([agenix][agenix]) and [Home Manager][home-manager]
  ([homeage][homeage]) with [age][age]
* Secure boot support using [Lanzaboote][lanzaboote]
* Checks source code with [shellcheck][shellcheck], [statix][statix] and [nixfmt][nixfmt]
* Weekly automatic flake input updates committed to master when CI passes

## Supported configurations

* [Nix-on-Droid][nix-on-droid]-managed
  * `nix-on-droid`
* [NixOS][nixos]-managed
  * `nixos-vm`
* [Home Manager][home-manager]-managed
  * `non-nixos-vm`

See [flake.nix](flake.nix) for more information like `system`.

## Structure

```text
📂 .
├──🔒 flake.lock    -- flake lockfile
├── ❄ flake.nix     -- flake definition
├──📂 home          -- Home Manager configuration
│  ├──📂 base       -- basic configs
│  ├──📂 programs   -- custom program modules
│  ├──📂 roles      -- custom roles for bundling configsets
│  └──📂 users      -- user-specific config
├──📂 hosts         -- NixOS host configs
│  ├──📂 nixos-vm
│  ├──📂 nix-on-droid
│  └──📂 non-nixos-vm
├──📂 lib           -- internal flake library
├──📂 nix-on-droid  -- custom NixOnDroid modules
├──📂 nixos         -- custom NixOS modules
│  ├──📂 base       -- basic configs
│  │   └──📂 users  -- user configs
│  ├──📂 containers -- custom container modules
│  ├──📂 programs   -- custom program modules
│  └──📂 roles      -- custom roles for bundling configsets
└──📂 secrets       -- agenix-encrypted secrets
```

## Usage

This flake can be either extended/modified directly or be used as a library.

### Directly

If you are not planning to use this flake for multiple Nix configurations, feel free to fork this
repo and add your host and user configurations into the folder structure and reference them in the
`flake.nix`:

```nix
{
  description = "Custom config flake";

  inputs = {
    # ...
  };

  outputs = { self, nixpkgs, ... } @ inputs:
    let
      # ...
    in
    {
      homeConfigurations = listToAttrs [
        (mkHome x86_64-linux "demo@non-nixos-host")
      ];

      nixosConfigurations = listToAttrs [
        (mkNixos x86_64-linux "nixos-host")
      ];

      # ...
    };
}
```

### As a Library

Create a new flake and prepare the folder structure as above, according to your needs. Then, add
this flake to the inputs and define your hosts and users in the `flake.nix`:

```nix
{
  description = "Custom config flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-22.05";
    nixcfg.url = "github:rake5k/nixcfg";
  };

  outputs = { nixpkgs, nixcfg, ... } @ inputs:
    let
      nixcfgLib = nixcfg.lib { inherit inputs; };

      # ...
    in
    with nixcfgLib;
    {
      homeConfigurations = listToAttrs [
        (mkHome x86_64-linux "demo@non-nixos-host")
      ];

      nixosConfigurations = listToAttrs [
        (mkNixos x86_64-linux "nixos-host")
      ];
    };
}
```

## Initial Setup

### NixOS

#### NixOS installation

To install NixOS from the ISO of [nixos.org][nixos] on a fresh machine, run:

```bash
sudo su # become root
mkdir -p ~/.config/nix
echo "experimental-features = nix-command flakes" > ~/.config/nix/nix.conf

export FLAKE=github:rake5k/nixcfg
export NIX_CONFIG="extra-access-tokens = github.com=github_pat_**********************************************************************************"
nix run $FLAKE#disko-install -- <hostname> $FLAKE
```

Where `<hostname>` is your target machine's desired host name. Define it
beforehand inside `nixosConfigurations` of `flake.nix`.

This will completely *nuke* all the data on your `<disk>` devices listed in the
*disko* configuration. Make sure to have a working backup from your data of all
drives connected to your target machine.

**Warning:** Even if the script *should* ask you before committing any changes to your machine,
it can unexpectedly cause great harm!

After rebooting proceed with the [next section](#nixos-config-setup).

#### NixOS config setup

```bash
sudo nix run github:rake5k/nixcfg#setup -- https://github.com/rake5k/nixcfg.git
```

### Non-NixOS

#### Nix installation

```bash
# install Nix
mkdir -p ~/.config/nix
echo "experimental-features = nix-command flakes" > ~/.config/nix/nix.conf
sh <(curl -L https://nixos.org/nix/install) --no-channel-add --no-modify-profile
. ~/.nix-profile/etc/profile.d/nix.sh
```

#### Nix config setup

```bash
# Set up this Nix configuration
nix run github:rake5k/nixcfg#setup -- https://github.com/rake5k/nixcfg.git

# set login shell
chsh -s /bin/zsh
```

#### Nix-on-Droid setup

```bash
nix-on-droid switch --flake github:rake5k/nixcfg#<hostname>
```

## Secrets management

### Make secrets available on new host

Add the host public key into the [.agenix.toml](.agenix.toml) file and assign it to the appropriate
groups. Push the updated `.agenix.toml` back to the git repository, pull it to an existing host and
re-key all the secrets with the command:

```bash
# On NixOS:
sudo agenix -i /etc/ssh/ssh_host_ed25519_key -i ~/.age/key.txt -r -vv

# On non-NixOS:
agenix -i ~/.age/key.txt -r -vv
```

After pushing/pulling the re-keyed secrets, just [run a rebuild](#rebuilding) of the new host's
config for decrypting them.

### Updating secrets

```bash
# First decrypt current secret
age --decrypt -i ~/.age/key.txt -o tmpfile < ./secrets/<secretfile>.age

# Update `tmpfile` contents...
vim tmpfile

# Re-encrypt the updated secret
age --encrypt --armor -i ~/.age/key.txt -o ./secrets/<secretfile>.age < tmpfile
```

## Updating inputs

This corresponds to the classical software/system update process known from other distros.

```shell
nix flake update
```

To apply (install) the updated inputs on the system, just [run a rebuild](#rebuilding) of the
config.

## Rebuilding

```bash
# On NixOS
sudo nixos-rebuild switch

# On non-NixOS
hm-switch
```

[ci]: https://garnix.io/repo/rake5k/nixcfg
[ci-badge]: https://img.shields.io/endpoint.svg?url=https%3A%2F%2Fgarnix.io%2Fapi%2Fbadges%2Frake5k%2Fnixcfg%3Fbranch%3Dmain

[age]: https://age-encryption.org/
[agenix]: https://github.com/ryantm/agenix
[disko]: https://github.com/nix-community/disko
[home-manager]: https://nix-community.github.io/home-manager
[homeage]: https://github.com/jordanisaacs/homeage
[lanzaboote]: https://github.com/nix-community/lanzaboote
[nix-on-droid]: https://nix-community.github.io/nix-on-droid
[nixos]: https://nixos.org/
[nixos-badge]: https://img.shields.io/badge/NixOS-24.11-blue.svg?logo=NixOS&logoColor=white
[nixfmt]: https://github.com/NixOS/nixfmt
[shellcheck]: https://github.com/koalaman/shellcheck
[statix]: https://github.com/NerdyPepper/statix
