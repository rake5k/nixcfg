{ lib, pkgs, config, ... } @args:

let

  nixCommons = import ../nix-commons args;
  nixSubstituters = import ../nix-commons/substituters.nix;

in

lib.recursiveUpdate nixCommons {
  nix = {
    nixPath = [ "nixpkgs=flake:nixpkgs" ];
    settings = {
      allowed-users = builtins.attrNames config.users.users;
      auto-optimise-store = lib.mkDefault true;
      experimental-features = [ "nix-command" "flakes" ];
      log-lines = 30;
    } // nixSubstituters;
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
