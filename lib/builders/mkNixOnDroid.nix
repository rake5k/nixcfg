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
    inherit (pkgs) config system;
    overlays = [ inputs.nix-on-droid.overlays.default ] ++ pkgs.overlays;
  };

in

inputs.nix-on-droid.lib.nixOnDroidConfiguration {

  pkgs = nodPkgs;

  extraSpecialArgs = {
    inherit homeModules inputs;
    pkgs = nodPkgs;
  };

  modules = [
    inputs.stylix.nixOnDroidModules.stylix
    inputs.stylix.homeModules.stylix

    ./modules/nix-nod

    # Host config
    "${inputs.self}/hosts/${name}"

    {
      custom.base.hostname = name;

      lib.custom = customLib;
    }

    # Home-Manager
    ./modules/home-manager
  ]
  ++ customLib.getRecursiveDefaultNixFileList ../../nix-on-droid;
}
