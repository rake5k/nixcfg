{
  inputs,
  pkgs,
  customLib,
  homeModules,
  name,
  ...
}:

let

  nodPkgs = import inputs.nixpkgs {
    inherit (pkgs) system;
    overlays = [ inputs.nix-on-droid.overlays.default ] + pkgs.overlays;
  };

in

inputs.nix-on-droid.lib.nixOnDroidConfiguration {

  pkgs = nodPkgs;

  extraSpecialArgs = {
    inherit homeModules inputs;
    pkgs = nodPkgs;
  };

  modules = [
    ./modules/nix-nod

    # Host config
    "${inputs.self}/hosts/${name}"

    {
      custom.base.hostname = name;

      lib.custom = customLib;

      nixpkgs = {
        pkgs = nodPkgs;
      };
    }
  ]
  ++ customLib.getRecursiveDefaultNixFileList ../../nix-on-droid;
}
