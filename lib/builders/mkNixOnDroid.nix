{
  inputs,
  pkgs,
  customLib,
  homeModules,
  name,
  ...
}:

inputs.nix-on-droid.lib.nixOnDroidConfiguration {

  extraSpecialArgs = {
    inherit homeModules inputs pkgs;
  };

  modules = [
    ./modules/nix-nod

    # Host config
    "${inputs.self}/hosts/${name}"

    {
      custom.base.hostname = name;

      lib.custom = customLib;

      nixpkgs = {
        inherit pkgs;
      };
    }
  ] ++ customLib.getRecursiveDefaultNixFileList ../../nix-on-droid;
}
