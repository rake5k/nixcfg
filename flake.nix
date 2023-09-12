{
  description = "NixOS & Home-Manager Configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    nur.url = "github:nix-community/NUR";

    flake-utils.url = "github:numtide/flake-utils";

    home-manager = {
      url = "github:nix-community/home-manager/release-23.05";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
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
      url = "github:jordanisaacs/homeage/release";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    kmonad = {
      url = "github:rake5k/kmonad?dir=nix";
      inputs = {
        nixpkgs.follows = "nixpkgs-unstable";
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
      inputs.nixpkgs.follows = "nixpkgs-unstable";
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

      overlays.default = nixpkgs.lib.composeManyExtensions [
        (final: prev: {
          shellcheckPicky = prev.writeShellScriptBin "shellcheck" ''
            ${inputs.nixpkgs.lib.getExe prev.shellcheck} \
            --check-sourced --enable all --external-sources \
            "$@"
          '';
        })
      ];

      checks = mkForEachSystem [
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
                entry = nixpkgs.lib.mkForce "${pkgs.lib.getExe pkgs.shellcheckPicky}";
              };
              statix.enable = true;
            };
          }))

        (mkBuild "build-nixos-vm" self.nixosConfigurations.nixos-vm.config.system.build.toplevel)
        (mkBuild "build-demo@non-nixos-vm" self.homeConfigurations."demo@non-nixos-vm".activationPackage)
        (mkBuild "build-christian@non-nixos-vm" self.homeConfigurations."christian@non-nixos-vm".activationPackage)
      ];

      devShells = mkForEachSystem [
        (mkDevShell "default" {
          name = "nixcfg";
          checksShellHook = system: self.checks."${system}".pre-commit-check.shellHook;
          packages = pkgs: with pkgs; [ nixpkgs-fmt shellcheck statix ];
        })
      ];
    };
}
