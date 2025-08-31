{
  inputs,
  name,
  pkgs,
  customLib,
  ...
}:

let

  # splits "username@hostname"
  splittedName = inputs.nixpkgs.lib.splitString "@" name;

  username = builtins.elemAt splittedName 0;
  hostname = builtins.elemAt splittedName 1;

in

inputs.home-manager.lib.homeManagerConfiguration {

  inherit pkgs;

  extraSpecialArgs = {
    inherit inputs;
  };

  modules = [
    inputs.homeage.homeManagerModules.homeage
    inputs.nix-index-database.homeModules.nix-index
    inputs.stylix.homeModules.stylix

    { lib.custom = customLib; }

    ./modules/nix-home

    "${inputs.self}/hosts/${hostname}/home-${username}.nix"
  ]
  ++ customLib.getRecursiveDefaultNixFileList ../../home
  ++ customLib.getRecursiveDefaultNixFileList "${inputs.self}/home";
}
