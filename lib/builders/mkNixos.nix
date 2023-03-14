{ inputs, system, pkgs, customLib, homeModules, name, ... }:

inputs.nixpkgs.lib.nixosSystem {
  inherit system;

  specialArgs = {
    inherit homeModules inputs;
  };

  modules = [
    "${inputs.self}/hosts/${name}"

    inputs.agenix.nixosModules.age
    inputs.home-manager.nixosModules.home-manager
    inputs.kmonad.nixosModules.default

    {
      custom.base.hostname = name;

      lib.custom = customLib;

      nixpkgs = {
        inherit pkgs;
      };
    }
  ]
  ++ customLib.getRecursiveDefaultNixFileList ../../nixos
  ++ customLib.getRecursiveDefaultNixFileList "${inputs.self}/nixos";
}

