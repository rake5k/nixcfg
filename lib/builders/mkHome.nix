{ inputs, pkgs, homeModules, name, ... }:

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
    ./modules/nix-commons
    "${inputs.self}/hosts/${hostname}/home-${username}.nix"
  ] ++ homeModules;
}
