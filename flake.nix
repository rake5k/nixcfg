{
  description = "NixOS & Home-Manager Configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-22.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    nur.url = "github:nix-community/NUR";

    flake-utils.url = "github:numtide/flake-utils";

    home-manager = {
      url = "github:nix-community/home-manager/release-22.11";
      inputs = {
        nixpkgs.follows = "nixpkgs-unstable";
        utils.follows = "flake-utils";
      };
    };

    pre-commit-hooks = {
      url = "github:cachix/pre-commit-hooks.nix?rev=6799201bec19b753a4ac305a53d34371e497941e";
      inputs = {
        flake-utils.follows = "flake-utils";
        nixpkgs.follows = "nixpkgs-unstable";
      };
    };

    # Modules

    flake-commons = {
      url = "github:christianharke/flake-commons";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        pre-commit-hooks.follows = "pre-commit-hooks";
      };
    };

    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    agenix-cli = {
      url = "github:cole-h/agenix-cli";
      inputs = {
        flake-utils.follows = "flake-utils";
        nixpkgs.follows = "nixpkgs";
      };
    };

    homeage = {
      url = "github:jordanisaacs/homeage/release";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    kmonad = {
      url = "github:christianharke/kmonad?dir=nix";
      inputs = {
        nixpkgs.follows = "nixpkgs";
      };
    };

    nixgl = {
      url = "github:guibou/nixGL";
      inputs = {
        nixpkgs.follows = "nixpkgs-unstable";
        flake-utils.follows = "flake-utils";
      };
    };

    nix-index-database = {
      url = "github:Mic92/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    spacevim = {
      url = "github:christianharke/spacevim-flake";
      inputs = {
        nixpkgs.follows = "nixpkgs-unstable";
        pre-commit-hooks.follows = "pre-commit-hooks";
      };
    };
  };

  outputs = { self, nixpkgs, ... } @ inputs:
    let
      nixcfgLib = import ./lib {
        inherit inputs;
      };
      inherit (inputs.flake-utils.lib.system) x86_64-linux;
      inherit (nixpkgs.lib) listToAttrs;
    in
    with nixcfgLib;
    {
      lib = { inputs }:
        import ./lib { inputs = inputs // self.inputs; };

      homeConfigurations = listToAttrs [
        (mkHome x86_64-linux "demo@non-nixos-vm")
        (mkHome x86_64-linux "christian@non-nixos-vm")
      ];

      nixosConfigurations = listToAttrs [
        (mkNixos x86_64-linux "nixos-vm")
      ];

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

      checks = mkForEachSystem [
        (mkGeneric "pre-commit-check" (system: inputs.pre-commit-hooks.lib."${system}".run {
          src = ./.;
          hooks = {
            nixpkgs-fmt.enable = true;
            shellcheck.enable = true;
            statix.enable = true;
          };
        }))

        (mkCheck "shellcheck" {
          script = mkShellCheck;
        })

        (mkCheck "nixpkgs-fmt" {
          script = pkgs: ''
            shopt -s globstar
            ${pkgs.nixpkgs-fmt}/bin/nixpkgs-fmt --check ${./.}/**/*.nix
          '';
        })

        (mkBuild "build-nixos-vm" self.nixosConfigurations.nixos-vm.config.system.build.toplevel)
        (mkBuild "build-demo@non-nixos-vm" self.homeConfigurations."demo@non-nixos-vm".activationPackage)
        (mkBuild "build-christian@non-nixos-vm" self.homeConfigurations."christian@non-nixos-vm".activationPackage)
      ];

      devShells = mkForEachSystem [
        (mkDevShell "default" {
          name = "nixcfg";
          checksShellHook = system: self.checks."${system}".pre-commit-check.shellHook;
          packages = pkgs: with pkgs; [ nixpkgs-fmt shellcheck statix ];
          customShellHook = mkShellCheck;
        })
      ];
    };
}
