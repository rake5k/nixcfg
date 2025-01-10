{
  description = "NixOS & Home-Manager Configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    nur.url = "github:nix-community/NUR";

    systems.url = "github:nix-systems/default";
    flake-utils = {
      url = "github:numtide/flake-utils";
      inputs.systems.follows = "systems";
    };

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    impermanence.url = "github:nix-community/impermanence";

    home-manager = {
      url = "github:nix-community/home-manager/release-24.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    darwin = {
      url = "github:lnl7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    nix-on-droid = {
      url = "github:nix-community/nix-on-droid/release-24.05";
      inputs.home-manager.follows = "home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    pre-commit-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs = {
        nixpkgs.follows = "nixpkgs-unstable";
      };
    };

    # Modules

    flake-commons = {
      url = "github:rake5k/flake-commons";
      inputs = {
        nixpkgs.follows = "nixpkgs-unstable";
        pre-commit-hooks.follows = "pre-commit-hooks";
      };
    };

    agenix = {
      url = "github:ryantm/agenix";
      inputs = {
        nixpkgs.follows = "nixpkgs-unstable";
        systems.follows = "systems";
      };
    };

    agenix-cli = {
      url = "github:cole-h/agenix-cli";
      inputs = {
        flake-utils.follows = "flake-utils";
        nixpkgs.follows = "nixpkgs-unstable";
      };
    };

    homeage = {
      url = "github:dbingham/homeage/checkConditionFix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    lanzaboote = {
      url = "github:nix-community/lanzaboote/v0.4.1";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    nixgl = {
      url = "github:nix-community/nixGL";
      inputs = {
        nixpkgs.follows = "nixpkgs-unstable";
        flake-utils.follows = "flake-utils";
      };
    };

    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
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

      formatter = forEachSystem (system: nixpkgs.legacyPackages."${system}".nixfmt-rfc-style);

      apps = mkForEachSystem [
        (mkApp "setup" {
          file = "setup.sh";
          envs = {
            _doNotClearPath = true;
            flakePath = "/home/\$(logname)/.nix-config";
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
