{
  description = "NixOS & Home-Manager Configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    nur.url = "github:nix-community/NUR";

    flake-utils.url = "github:numtide/flake-utils";

    home-manager = {
      url = "github:nix-community/home-manager/release-24.05";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    darwin = {
      url = "github:lnl7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    nix-on-droid = {
      url = "github:nix-community/nix-on-droid/release-23.11";
      inputs.home-manager.follows = "home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    pre-commit-hooks = {
      url = "github:cachix/pre-commit-hooks.nix";
      inputs = {
        flake-utils.follows = "flake-utils";
        nixpkgs.follows = "nixpkgs-unstable";
        nixpkgs-stable.follows = "nixpkgs";
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
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    agenix-cli = {
      url = "github:cole-h/agenix-cli";
      inputs = {
        flake-utils.follows = "flake-utils";
        nixpkgs.follows = "nixpkgs-unstable";
      };
    };

    homeage = {
      url = "github:jordanisaacs/homeage";
      inputs.nixpkgs.follows = "nixpkgs";
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
  };

  outputs = { self, nixpkgs, ... } @ inputs:
    let
      nixcfgLib = import ./lib {
        inherit inputs;
      };
      inherit (inputs.flake-utils.lib.system) aarch64-darwin aarch64-linux x86_64-linux;
      inherit (nixpkgs.lib) composeManyExtensions getExe listToAttrs mkForce recursiveUpdate;
    in
    with nixcfgLib;
    {
      lib = { inputs }:
        import ./lib { inputs = inputs // self.inputs; };

      darwinConfigurations = listToAttrs [
        (mkNixDarwin aarch64-darwin "macos")
      ];

      homeConfigurations = listToAttrs [
        (mkHome x86_64-linux "christian@non-nixos")
        (mkHome x86_64-linux "demo@non-nixos")
      ];

      nixosConfigurations = listToAttrs [
        (mkNixos x86_64-linux "nixos")
      ];

      nixOnDroidConfigurations = listToAttrs [
        (mkNixOnDroid aarch64-linux "nix-on-droid")
      ];

      formatter = forEachSystem (system: nixpkgs.legacyPackages."${system}".nixpkgs-fmt);

      apps = mkForEachSystem [
        (mkApp "setup" {
          file = "setup.sh";
          envs = {
            _doNotClearPath = true;
            flakePath = "/home/\$(logname)/.nix-config";
          };
          path = pkgs: with pkgs; [
            git
            hostname
            jq
          ];
        })

        (mkApp "nixos-install" {
          file = "nixos-install.sh";
          envs = {
            _doNotClearPath = true;
          };
          path = pkgs: with pkgs; [
            git
            hostname
            util-linux
            parted
            cryptsetup
            lvm2
          ];
        })
      ];

      overlays.default = composeManyExtensions [
        (final: prev: {
          shellcheckPicky = prev.writeShellScriptBin "shellcheck" ''
            ${getExe prev.shellcheck} \
            --check-sourced --enable all --external-sources \
            "$@"
          '';
        })
      ];

      checks = recursiveUpdate
        (mkForEachSystem [
          (mkGeneric "pre-commit-check" (system:
            let
              pkgs = import nixpkgs {
                inherit system;
                overlays = [ self.overlays.default ];
              };
            in
            inputs.pre-commit-hooks.lib."${system}".run {
              src = ./.;
              hooks = {
                nixpkgs-fmt.enable = true;
                shellcheck = {
                  enable = true;
                  entry = mkForce "${getExe pkgs.shellcheckPicky}";
                };
                statix.enable = true;
              };
            }))
        ])
        ((mkForSystem aarch64-darwin [
          (mkBuild "build-macos" self.darwinConfigurations.macos.system)
        ]) // (mkForSystem x86_64-linux [
          (mkBuild "build-christian@non-nixos" self.homeConfigurations."christian@non-nixos".activationPackage)
          (mkBuild "build-demo@non-nixos" self.homeConfigurations."demo@non-nixos".activationPackage)
          (mkBuild "build-nixos" self.nixosConfigurations.nixos.config.system.build.toplevel)
        ]));

      devShells = mkForEachSystem [
        (mkDevShell "default" {
          name = "nixcfg";
          checksShellHook = system: self.checks."${system}".pre-commit-check.shellHook;
          packages = pkgs: with pkgs; [ nixpkgs-fmt shellcheck statix ];
        })
      ];
    };
}
