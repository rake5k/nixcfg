{
  lib,
  pkgs,
  config,
  ...
}@args:

let

  nixCommons = import ../nix-commons args;

in

lib.recursiveUpdate nixCommons {
  nix = {
    nixPath = [ "nixpkgs=flake:nixpkgs" ];
    settings = {
      allowed-users = builtins.attrNames config.users.users;
    };
  };

  system.activationScripts.diff = {
    supportsDryActivation = true;
    text = ''
      if [[ -e /run/current-system ]]; then
         ${lib.getExe pkgs.nix} store diff-closures /run/current-system "$systemConfig"
      fi
    '';
  };
}
