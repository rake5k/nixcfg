{
  description = "NixOS & Home-Manager Configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    flake-commons = {
      url = "github:rake5k/flake-commons";
      inputs = {
        nixpkgs.follows = "nixpkgs-unstable";
        pre-commit-hooks.follows = "pre-commit-hooks";
      };
    };

    nur = {
      url = "github:nix-community/NUR";
      inputs = {
        nixpkgs.follows = "nixpkgs-unstable";
        flake-parts.follows = "flake-parts";
      };
    };

    pre-commit-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs = {
        nixpkgs.follows = "nixpkgs-unstable";
        flake-compat.follows = "flake-compat";
      };
    };

    # Flake utils

    systems.url = "github:nix-systems/default";

    flake-compat.url = "github:edolstra/flake-compat";

    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs-unstable";
    };

    flake-utils = {
      url = "github:numtide/flake-utils";
      inputs.systems.follows = "systems";
    };

    # Configuration types

    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    darwin = {
      url = "github:lnl7/nix-darwin/nix-darwin-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-on-droid = {
      url = "github:nix-community/nix-on-droid/release-24.05";
      inputs.home-manager.follows = "home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Modules

    agenix = {
      url = "github:ryantm/agenix";
      inputs = {
        nixpkgs.follows = "nixpkgs-unstable";
        home-manager.follows = "home-manager";
        systems.follows = "systems";
      };
    };

    agenix-cli = {
      url = "github:cole-h/agenix-cli";
      inputs = {
        flake-compat.follows = "flake-compat";
        flake-utils.follows = "flake-utils";
        nixpkgs.follows = "nixpkgs-unstable";
      };
    };

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    homeage = {
      url = "github:dbingham/homeage/checkConditionFix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    impermanence.url = "github:nix-community/impermanence";

    lanzaboote = {
      url = "github:nix-community/lanzaboote/v0.4.2";
      inputs = {
        nixpkgs.follows = "nixpkgs-unstable";
        flake-compat.follows = "flake-compat";
        flake-parts.follows = "flake-parts";
        pre-commit-hooks-nix.follows = "pre-commit-hooks";
      };
    };

    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    nixgl = {
      url = "github:nix-community/nixGL";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-utils.follows = "flake-utils";
      };
    };

    # Misc

    wallpapers = {
      type = "gitlab";
      owner = "rake5k";
      repo = "wallpapers";
      flake = false;
    };
  };

  outputs =
    { self, nixpkgs, ... }@inputs:
    let
      nixcfgLib = import ./lib { inherit inputs; };
      inherit (inputs.flake-utils.lib.system) aarch64-darwin aarch64-linux x86_64-linux;
      inherit (nixpkgs.lib) listToAttrs;
    in
    with nixcfgLib;
    {
      name = "nixcfg";

      lib = { inputs }: import ./lib { inputs = inputs // self.inputs; };

      darwinConfigurations = listToAttrs [ (mkNixDarwin aarch64-darwin "macos") ];

      homeConfigurations = listToAttrs [
        (mkHome x86_64-linux "christian@non-nixos")
        (mkHome x86_64-linux "demo@non-nixos")
      ];

      nixosConfigurations = listToAttrs [ (mkNixos x86_64-linux "nixos") ];

      nixOnDroidConfigurations = listToAttrs [ (mkNixOnDroid aarch64-linux "nix-on-droid") ];

      formatter = forEachSystem (system: nixpkgs.legacyPackages."${system}".nixfmt-tree);

      apps = mkForEachSystem [
        (mkApp "setup" {
          file = "setup.sh";
          envs = {
            _doNotClearPath = true;
            flakePath = "/home/\$(logname)/.nix-config";
          };
          meta = {
            description = "Setup script for applying this system configuration";
            license = licenses.mit;
            maintainers = with maintainers; [ rake5k ];
            platforms = platforms.all;
          };
          path =
            pkgs: with pkgs; [
              git
              hostname
              jq
            ];
        })

        (mkApp "disko-install" {
          file = "disko-install.sh";
          envs = {
            _doNotClearPath = true;
          };
          meta = {
            description = "Installation script including disk partitioning";
            license = licenses.mit;
            maintainers = with maintainers; [ rake5k ];
            platforms = platforms.all;
          };
        })
      ];

      checks = forEachSystem (
        system:
        let
          commonsLib = inputs.flake-commons.lib {
            pkgs = pkgsFor."${system}";
            flake = self;
          };
        in
        commonsLib.checks
      );

      devShells = mkForEachSystem [ (mkDevShell "default" { flake = self; }) ];

      # Necessary for nix-tree
      # Run it using `nix-tree . --impure --derivation`
      packages = {
        x86_64-linux.default = self.nixosConfigurations.nixos.config.system.build.toplevel;
        aarch64-darwin.default = self.darwinConfigurations.macos.system;
      };
    };
}
