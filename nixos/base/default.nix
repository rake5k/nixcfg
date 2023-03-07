{ config, lib, pkgs, homeModules, inputs, rootPath, ... } @ args:

with lib;

let

  cfg = config.custom.base;

  availableUsers = [ "christian" "demo" ];
  importUserModule = u:
    let
      isEnabled = any (x: x == u) cfg.users;
      userConfig = ./users + "/${u}.nix";
    in
    mkIf isEnabled (import userConfig args);
  importUserModules = map importUserModule availableUsers;

  importHmUser = with config.lib.custom;
    u: import (mkHostPath cfg.hostname "/home-${u}.nix");
  hmUsers = genAttrs cfg.users importHmUser;

in

{
  imports = importUserModules;

  options = {
    custom.base = {
      hostname = mkOption {
        type = types.enum [ "altair" "bcr-nl011" "nixos-vm" ];
        description = "Host name.";
      };

      users = mkOption {
        type = types.listOf (types.enum availableUsers);
        default = [ ];
        description = "List of user names.";
      };
    };
  };

  config = {

    boot = {
      cleanTmpDir = true;
    };

    home-manager = {
      backupFileExtension = "hm-bak";
      useGlobalPkgs = true;
      useUserPackages = true;
      extraSpecialArgs = { inherit inputs rootPath; };
      sharedModules = homeModules;
      users = hmUsers;
    };

    networking = {
      hostName = cfg.hostname;
    };

    programs = {
      vim.defaultEditor = true;
      zsh.enable = true;
    };

    security.sudo.package = pkgs.sudo.override {
      withInsults = true;
    };

    services = {
      logind.extraConfig = ''
        HandlePowerKey=ignore
      '';
    };
  };
}
