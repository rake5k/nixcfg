{ inputs, system, pkgs, customLib, homeModules, name, ... }:

inputs.nix-on-droid.lib.nixOnDroidConfiguration {

  extraSpecialArgs = {
    inherit inputs pkgs homeModules;
  };

  modules = [
    "${inputs.self}/hosts/${name}"

    {
      custom.base.hostname = name;

      lib.custom = customLib;
    }
  ]
  ++ customLib.getRecursiveDefaultNixFileList ../../nix-on-droid;
}
