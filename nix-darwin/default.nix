{ config, lib, pkgs, homeModules, inputs, ... }:

with lib;

let

  cfg = config.custom.base;

  # TODO: extract duplicate of nixos/base
  importHmUser = with config.lib.custom;
    u: import (mkHostPath cfg.hostname "/home-${u}.nix");
  hmUsers = genAttrs cfg.users importHmUser;

in

{
  options = {
    custom.base = {
      hostname = mkOption {
        type = types.str;
        description = "Host name.";
      };

      users = mkOption {
        type = with types; listOf str;
        default = [ ];
        description = "List of user names.";
      };
    };
  };

  config = {
    # TODO: extract duplicate from nixos/base
    home-manager = {
      backupFileExtension = "hm-bak";
      useGlobalPkgs = true;
      useUserPackages = true;
      extraSpecialArgs = { inherit inputs; };
      sharedModules = homeModules;
      users = hmUsers;
    };

    # Make sure the nix daemon always runs
    services.nix-daemon.enable = true;
  };
}
