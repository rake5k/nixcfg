{
  inputs,
  pkgs,
  customLib,
  name,
  ...
}:

inputs.nixpkgs.lib.nixosSystem {

  specialArgs = {
    inherit inputs;
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

    # Disko
    inputs.disko.nixosModules.disko

    # Impermanence
    inputs.impermanence.nixosModules.impermanence

    # Secure Boot
    inputs.lanzaboote.nixosModules.lanzaboote

    # Home-Manager
    inputs.home-manager.nixosModules.home-manager
    ./modules/home-manager
    ./modules/home-manager-users
  ]
  ++ customLib.getRecursiveDefaultNixFileList ../../nixos
  ++ customLib.getRecursiveDefaultNixFileList "${inputs.self}/nixos";
}
