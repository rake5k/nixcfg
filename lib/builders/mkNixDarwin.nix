{ inputs, system, pkgs, customLib, homeModules, name, ... }:

inputs.darwin.lib.darwinSystem {

  inherit system;

  specialArgs = {
    inherit homeModules inputs;
  };

  modules = [
    ./modules/nix

    # Host config
    "${inputs.self}/hosts/${name}"

    {
      custom.base.hostname = name;

      lib.custom = customLib;

      nixpkgs = {
        inherit pkgs;
      };
    }

    # Home-Manager
    inputs.home-manager.darwinModules.home-manager
    ./modules/home-manager
    ./modules/home-manager-users
  ]
  ++ customLib.getRecursiveDefaultNixFileList ../../nix-darwin
  ++ customLib.getRecursiveDefaultNixFileList "${inputs.self}/nix-darwin";
}

