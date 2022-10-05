# :snowflake: Nix Configuration

[![NixOS][nixos-badge]][nixos]
[![Build and Test][ci-badge]][ci]
[![Update][update-badge]][update]

## Features

* Automation scripts to setup a fresh [NixOS machine from scratch](flake/apps/nixos-install.sh) or
  an [arbitrary preinstalled Linux machine](flake/apps/setup.sh) easily
* Secret management in [NixOS][nixos] ([agenix][agenix]) and [Home Manager][home-manager]
  ([homeage][homeage]) with [age][age]
* Checks source code with [shellcheck][shellcheck] and [nixpkgs-fmt][nixpkgs-fmt]
* Daily automatic flake input updates committed to master when CI passes

## Supported configurations

* [NixOS][nixos]-managed
  * `nixos-vm`
* [Home Manager][home-manager]-managed
  * `non-nixos-vm`

See [flake.nix](flake.nix) for more information like `system`.

## Structure

```
📂 .
├──📂 flake         -- internal flake library
├──🔒 flake.lock    -- flake lockfile
├── ❄ flake.nix     -- flake definition
├──📂 home          -- Home Manager configuration
│  ├──📂 base       -- basic configs
│  ├──📂 programs   -- custom program modules
│  ├──📂 roles      -- custom roles for bundling configsets
│  └──📂 users      -- user-specific config
├──📂 hosts         -- NixOS host configs
│  └──📂 nixos-vm
├──📂 nixos         -- custom NixOS modules
│  ├──📂 base       -- basic configs
│  │   └──📂 users  -- user configs
│  ├──📂 containers -- custom container modules
│  ├──📂 programs   -- custom program modules
│  └──📂 roles      -- custom roles for bundling configsets
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
        (mkHome "x86_64-linux" "demo@non-nixos-host")
      ];

      nixosConfigurations = listToAttrs [
        (mkNixos "x86_64-linux" "nixos-host")
      ];
    }
    // eachSystem ({ mkGeneric, mkApp, mkCheck, getDevShell, mkDevShell, ... }:
        # ...
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
    nixcfg.url = "github:christianharke/nixcfg";
  };

  outputs = { nixpkgs, nixcfg, ... } @ inputs:
    let
      nixcfgLib = nixcfg.lib."x86_64-linux" {
        inherit (inputs.nixcfg) inputs;
        rootPath = ./.;
      };

      inherit (nixpkgs.lib) listToAttrs;
      inherit (nixcfgLib) mkHome mkNixos;
    in
    {
      homeConfigurations = listToAttrs [
        (mkHome "x86_64-linux" "demo@non-nixos-host")
      ];

      nixosConfigurations = listToAttrs [
        (mkNixos "x86_64-linux" "nixos-host")
      ];
    };
}
```

## Initial Setup

### NixOS

#### NixOS installation

To install NixOS from the ISO of [nixos.org][nixos] on a fresh machine, run:

```bash
# If nix version < 2.4, run:
nix-shell -p nixFlakes

sudo su # become root
mkdir -p ~/.config/nix
echo "experimental-features = nix-command flakes" > ~/.config/nix/nix.conf

nix run github:christianharke/nixcfg#nixos-install -- <hostname> <disk>
```

Where:

* `<hostname>` is your target machine's desired host name. Define it beforehand inside
  `nixosConfigurations` of `flake.nix`.
* `<disk>` is your target drive to install NixOS on. Accepted values are `/dev/sda`, `/dev/nvme0n1`
  or the like.

This will completely *nuke* all the data on your `<disk>` device provided. Make sure to have a
working backup from your data of all drives connected to your target machine.

**Warning:** Even if the script *should* ask you before committing any changes to your machine,
it can unexpectedly cause great harm!

After rebooting proceed with the [next section](#nixos-config-setup).

#### NixOS config setup

```bash
$ sudo nix run github:christianharke/nixcfg#setup
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
nix run github:christianharke/nixcfg#setup

# set login shell
chsh -s /bin/zsh
```

## Secrets management

### Make secrets available on new host

The setup script will create the [age][age] keys needed and put them in the
[.agenix.toml](.agenix.toml) file, where it then needs to be assigned to the appropriate groups.
Push the updated `.agenix.toml` back to the git repository, pull it to an existing host and
re-key all the secrets with the command:

```bash
$ # On NixOS:
$ sudo agenix -i /root/.age/key.txt -i ~/.age/key.txt -r -vv

$ # On non-NixOS:
$ agenix -i ~/.age/key.txt -r -vv
```

After pushing/pulling the re-keyed secrets, just [run a rebuild](#rebuilding) of the new host's
config for decrypting them.

### Updating secrets

```bash
$ # First decrypt current secret
$ age --decrypt -i ~/.age/key.txt -o tmpfile < ./secrets/<secretfile>.age

$ # Update `tmpfile` contents...
$ vim tmpfile

$ # Re-encrypt the updated secret
$ age --encrypt -i ~/.age/key.txt -o ./secrets/<secretfile>.age < tmpfile
```

## Updating inputs

This corresponds to the classical software/system update process known from other distros.

```bash
$ nix flake update
```

To apply (install) the updated inputs on the system, just [run a rebuild](#rebuilding) of the
config.

## Rebuilding

```bash
$ # On NixOS
$ sudo nixos-rebuild switch

$ # On non-NixOS
$ hm-switch
```

[ci]: https://github.com/christianharke/nixcfg/actions/workflows/ci.yml
[ci-badge]: https://github.com/christianharke/nixcfg/actions/workflows/ci.yml/badge.svg
[update]: https://github.com/christianharke/nixcfg/actions/workflows/update.yml
[update-badge]: https://github.com/christianharke/nixcfg/actions/workflows/update.yml/badge.svg

[age]: https://age-encryption.org/
[agenix]: https://github.com/ryantm/agenix
[home-manager]: https://github.com/nix-community/home-manager
[homeage]: https://github.com/jordanisaacs/homeage
[nixos]: https://nixos.org/
[nixos-badge]: https://img.shields.io/badge/NixOS-22.05-blue.svg?logo=NixOS&logoColor=white
[nixpkgs-fmt]: https://github.com/nix-community/nixpkgs-fmt
[shellcheck]: https://github.com/koalaman/shellcheck

