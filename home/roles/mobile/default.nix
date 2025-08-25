{ config, lib, ... }:

with lib;

let

  cfg = config.custom.roles.mobile;

in

{
  options = {
    custom.roles.mobile = {
      enable = mkEnableOption "Mobile";
    };
  };

  config = mkIf cfg.enable {
    homeage = {
      installationType = "activation";
      mount = "${config.xdg.dataHome}/homeage";
    };

    home.activation.symlinkStorageDocuments = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      $DRY_RUN_CMD ln -fs $VERBOSE_ARG /storage/emulated/0/Documents $HOME
    '';

    custom = {
      base.nix-on-droid.enable = true;

      roles = {
        mobile = {
          bin.enable = true;
          wiki.enable = true;
        };
      };
    };
  };
}
