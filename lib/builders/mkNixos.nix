{
  inputs,
  pkgs,
  customLib,
  homeModules,
  name,
  ...
}:

inputs.nixpkgs.lib.nixosSystem {

  specialArgs = {
    inherit homeModules inputs;
  };

  modules =
    [
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
      inputs.home-manager.nixosModules.home-manager
      ./modules/home-manager
      ./modules/home-manager-users
    ]
    ++ customLib.getRecursiveDefaultNixFileList ../../nixos
    ++ customLib.getRecursiveDefaultNixFileList "${inputs.self}/nixos";
}
