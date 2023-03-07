{ inputs, rootPath, system, pkgs, customLib, homeModules, name, ... }:

inputs.nixpkgs.lib.nixosSystem {
  inherit system;

  specialArgs = {
    inherit homeModules inputs rootPath;
  };

  modules = [
    (rootPath + "/hosts/${name}")

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
  ++ customLib.getRecursiveDefaultNixFileList (rootPath + "/nixos");
}

