{ inputs, system, pkgs, customLib, homeModules, name, ... }:

inputs.darwin.lib.darwinSystem {
  inherit system;

  specialArgs = {
    inherit homeModules inputs;
  };

  modules = [
    ./modules/nix
    inputs.home-manager.darwinModules.home-manager
    "${inputs.self}/hosts/${name}"

    {
      custom.base.hostname = name;

      lib.custom = customLib;

      nixpkgs = {
        inherit pkgs;
      };
    }
  ]
  ++ customLib.getRecursiveDefaultNixFileList ../../nix-darwin
  ++ customLib.getRecursiveDefaultNixFileList "${inputs.self}/nix-darwin";
}

